import GLKit
import ParsecSDK

class ParsecGLKRenderer:NSObject, GLKViewDelegate, GLKViewControllerDelegate
{
	var glkView:GLKView
	var glkViewController:GLKViewController
	
	var lastWidth:CGFloat = 1.0

	var lastImg: CGImage?
	let updateImage: () -> Void
	
	// FPS tracking
	private var frameCount: Int = 0
	private var lastFPSUpdate: CFTimeInterval = 0
	static var currentFPS: Double = 0
	
	// Background pause flag
	static var isPaused: Bool = false
	
	init(_ view:GLKView, _ viewController:GLKViewController,_ updateImage: @escaping () -> Void)
	{
		self.updateImage = updateImage
		glkView = view
		glkViewController = viewController
		self.lastFPSUpdate = CACurrentMediaTime()

		super.init()

		glkView.delegate = self
		glkViewController.delegate = self

	}

	deinit
	{
		glkView.delegate = nil
		glkViewController.delegate = nil
	}

	func glkView(_ view:GLKView, drawIn rect:CGRect)
	{
		// Skip rendering when app is in background to prevent decode errors
		if ParsecGLKRenderer.isPaused {
			return
		}
		
		let deltaWidth: CGFloat = view.frame.size.width - lastWidth
		if deltaWidth > 0.1 || deltaWidth < -0.1
		{
		    CParsec.setFrame(view.frame.size.width, view.frame.size.height, view.contentScaleFactor)
	        lastWidth = view.frame.size.width
		}
		// Dynamic timeout based on performance mode:
		// - Quality: 16ms (relaxed, saves battery)
		// - Balanced: 12ms (good balance)
		// - Low Latency: 4ms (aggressive, minimal delay)
		let timeout: UInt32
		switch SettingsHandler.performanceMode {
		case .quality:
			timeout = 16
		case .balanced:
			timeout = 12
		case .lowLatency:
			timeout = 4
		}
		CParsec.renderGLFrame(timeout: timeout)
		
		// FPS calculation
		frameCount += 1
		let currentTime = CACurrentMediaTime()
		let elapsed = currentTime - lastFPSUpdate
		if elapsed >= 1.0 {
			ParsecGLKRenderer.currentFPS = Double(frameCount) / elapsed
			frameCount = 0
			lastFPSUpdate = currentTime
		}
		
		updateImage()
		

//		glFinish()
		//glFlush()
	}

	func glkViewControllerUpdate(_ controller:GLKViewController) { }
}
