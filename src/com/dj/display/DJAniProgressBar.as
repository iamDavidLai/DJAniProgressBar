package com.dj.display
{
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import caurina.transitions.Tweener;

	
	/**
	 * ...
	 * @author 	David Lai & Jost Kuan
	 * @version	1.0.0
	 * @reference Jack Terfict
	 * @remark		To control the progress of timeline animation.
	 * 	
	 * @created 	2015/01/07
	 * @updated 	2016/08/24
	 * @usuage	For export swc,
	 * 				You have to bundle the Class with the component of library in Flash(Animate). 
	 * 
	 * 
	 */
	
	 
	public class DJAniProgressBar extends MovieClip
	{
		private static const PLAY:String = "play";			
		private static const PAUSE:String = "pause";
		private static const STOP:String = "stop";
		private static var state:String;								// 播放控制器的狀態
		
		private const MOVE_OFFSET_Y:int = 100;				// 隱藏「控制Bar」的Y_POS偏移值參數 (與實際 UI 比例有關)
		
		public var play_btn:SimpleButton;							// 播放
		public var pause_btn:SimpleButton;							// 暫停
		public var stop_btn:SimpleButton;							// 停止，回到第一影格
		public var slider_mc:MovieClip;								// 控制器，MC才有StarDrag()
		public var track_mc:MovieClip;								// 進度條
		public var arrow_mc:MovieClip;								// 箭頭 控制播放面板的動態顯示與否
		
		private var _parent:MovieClip;								// DisplayObjectContainer as parent, MainTimeline or MovieClip
		private var _dragRect:Rectangle;							// 能夠拖曳的實際範圍，以進度條為基準
		private var _newFrame:int;									// 移動控制Bar後，要重新開始播放的第 ? 影格
		private var _isPlayToEnd:Boolean;							// 確認是否播放到最後一個影格, 預設是播放動動畫末端就STOP不再繼續PLAY
		private var _isDisplay:Boolean;								// 記錄是否為已顯示狀態or移動到場景外隱藏(還需要外層MASK才能確實隱藏)
		
		
		
		public function DJAniProgressBar(_parent:MovieClip) {
			this.stop();
			this._parent = _parent;
			this.addEventListener(Event.ADDED_TO_STAGE, added);
			this.addEventListener(Event.REMOVED_FROM_STAGE, dispose);
			
			if (this._parent) {
				this._parent.addChildAt(this, this._parent.numChildren - 1);
			}
		}
		
		/**	Initialize.....	**/
		private function added(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, added);
			this.play_btn.addEventListener(MouseEvent.CLICK, onClick);
			this.pause_btn.addEventListener(MouseEvent.CLICK, onClick);
			this.stop_btn.addEventListener(MouseEvent.CLICK, onClick);
			this.arrow_mc.addEventListener(MouseEvent.CLICK, onClick);
			this.arrow_mc.buttonMode = true;
			this.slider_mc.buttonMode = true;
			this.slider_mc.addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
			if (this._parent) stage.addEventListener(Event.ENTER_FRAME, onProgressChange);
			
			//
			// Basic init
			//
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			DJAniProgressBar.state = DJAniProgressBar.PLAY;
			this.x = stage.stageWidth / 2;
			this.y = stage.stageHeight + this.MOVE_OFFSET_Y;
			this.slider_mc.y = this.track_mc.y;
			this._dragRect = new Rectangle(this.track_mc.x, this.track_mc.y, this.track_mc.width, 0);	
				
			//
			// Setting MASK
			//
			var _mask:Sprite = new Sprite;
			_mask.graphics.beginFill(0xFF00FF, 0.25);								// must beginFill first ..........=_=
			_mask.graphics.drawRect(-27, 0, 854, 480);
			_mask.graphics.endFill();
			this._parent.addChild(_mask);
			this._parent.mask = _mask;
		}
		
		private function dispose(e:Event):void {
			this.removeEventListener(Event.REMOVED_FROM_STAGE, dispose);
			this.play_btn.removeEventListener(MouseEvent.CLICK, onClick);
			this.pause_btn.removeEventListener(MouseEvent.CLICK, onClick);
			this.stop_btn.removeEventListener(MouseEvent.CLICK, onClick);
			this.arrow_mc.removeEventListener(MouseEvent.CLICK, onClick);
			this.slider_mc.removeEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
			this._parent.stop();
			if (this._parent) {
				stage.removeEventListener(Event.ENTER_FRAME, onProgressChange);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
				stage.removeEventListener(MouseEvent.MOUSE_OUT, mouseHandler);
				stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);
			}
		}
		
		
		private function onClick(e:MouseEvent):void {
			switch(e.target.name) {
				case "play_btn":			
					this._parent.play();
					DJAniProgressBar.state = DJAniProgressBar.PLAY;
					break;
					
				case "pause_btn":
					DJAniProgressBar.state = DJAniProgressBar.PAUSE;
					break;
					
				case "stop_btn":
					DJAniProgressBar.state = DJAniProgressBar.STOP;
					break;	
					
				case "arrow_mc":
					this.controlProgressBarDisplay();
					break;
			}
			//trace("state: " + DJAniProgressBar.state);
		}
		
		/**	slider_mc is pressed	*/
		private function controlProgressBarDisplay():void {
			if (!this._isDisplay) {
				Tweener.addTween(this, { time:0.5, y:stage.stageHeight, onComplete:onMotionComplete, transition:"easeOutQuint" });										// SHOW
			}else {
				Tweener.addTween(this, { time:0.5, y:stage.stageHeight + this.MOVE_OFFSET_Y, onComplete:onMotionComplete, transition:"easeOutQuint" });		// HIDE
			}
			this.arrow_mc.removeEventListener(MouseEvent.CLICK, onClick);
		}
		
		/**	arrow_mc Tween motion onComplete	*/
		private function onMotionComplete():void {
			if (!this._isDisplay) {
				this.arrow_mc.gotoAndStop(2);
			}else {
				this.arrow_mc.gotoAndStop(1);
			}
			this._isDisplay = !this._isDisplay;
			this.arrow_mc.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		
		
		/**	slider_mc is pressed	*/
		private function mouseHandler(e:MouseEvent):void {
			//trace(e.type);
			switch(e.type) {
				case "mouseDown":
					this._parent.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);			// 目前以stage mouseMove才能掌控移動範圍
					this._parent.stage.addEventListener(MouseEvent.MOUSE_UP, mouseHandler);
					
					// 
					// KEEP IT FOR REFERENCE
					//
					//this._parent.stage.addEventListener(MouseEvent.MOUSE_OUT, mouseHandler);			// for Win, 離開播放範圍卻還能控制有點不合理?  真實範圍卻只有在離開 slider_mc 後觸發 (有點奇怪?) 
					//this._parent.stage.addEventListener(MouseEvent.ROLL_OUT, mouseHandler);				// 承上, 但Windows 上的Youtube progressBar 也可在整個螢幕操作MOUSE_MOVE........保留
					//this.slider_mc.addEventListener(MouseEvent.MOUSE_OUT, mouseHandler);
					break;																												// 可能因為是slider_mc - mouseDown 觸發, 離開後便失效
					
				case "mouseMove":
					e.updateAfterEvent();
					this.slider_mc.startDrag(true, this._dragRect);
					//this.slider_mc.startDrag(false, this._dragRect);														// for test
					this.updatePosition();																							// Update current frame
					(this._parent) this._parent.addChildAt(this, this._parent.numChildren - 1);						// keep index always on the top
					
					break;																												
					
				//	
				// KEEP IT FOR REFERENCE
				//
				//case "mouseOut":
					//trace("MOUSE_OUT");
					//this.slider_mc.removeEventListener(MouseEvent.MOUSE_OUT, mouseHandler);
					//this._parent.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
					//this._parent.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);
					//this.slider_mc.stopDrag();
					//trace("this._isPlayToEnd: " + this._isPlayToEnd);
					//break;
				//case "rollOut":
					//trace("ROLL_OUT");
					//this._parent.stage.removeEventListener(MouseEvent.ROLL_OUT, mouseHandler);
					
					
				case "mouseUp":
					this._parent.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
					this._parent.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);
					this.slider_mc.stopDrag();
					this.frameGotoAndplay();																						// mouseUp 時就要根據mouseMove移動到哪個影格繼續播放
					break;
			}
		}

		/**	MOUSE_MOVE	*/
		private function updatePosition():void {
			DJAniProgressBar.state = DJAniProgressBar.PAUSE;
			
			///***According to ProgressSlider's x.Position, 計算新的影格播放位置 - this.newPos(秒數)***/
			this._newFrame = Math.ceil((this.slider_mc.x - this.track_mc.x) / this.track_mc.width * this._parent.totalFrames);			// (0 ~ 350) / 350 * 150;
			this._parent.gotoAndStop(this._newFrame);
			//trace("MOVE_newFrame: " + this._newFrame);
			
		}
		
		/**	MOUSE_UP	*/
		private function frameGotoAndplay():void {																		//trace("UP_newFrame: " + this._newFrame);
			if (this._newFrame == this._parent.totalFrames) 	return;												// LAST FRAME DO NOT PLAY
			
			DJAniProgressBar.state = DJAniProgressBar.PLAY;
			this._parent.gotoAndPlay(this._newFrame);
		}
		
		
		/**	MovieClip on enterFrame	*/
		private function onProgressChange(e:Event):void {
			this._parent.addChildAt(this, this._parent.numChildren - 1);
			
			// 當播放到最後一影格時, 應隨之停止不再從頭播放。除非按下PLAY or 拖曳slider_mc
			if ((this._parent.currentFrame >= this._parent.totalFrames) && (!this._isPlayToEnd)) {				// trace("END");					trace("=====================");
				this._parent.gotoAndStop(this._parent.totalFrames);
				this._isPlayToEnd = true;	
				DJAniProgressBar.state = DJAniProgressBar.PAUSE;															// trace("this._parent.currentFrame:" + this._parent.currentFrame);		
			}
			
			this.slider_mc.x = this.track_mc.x + this.track_mc.width * (this._parent.currentFrame / this._parent.totalFrames);
			
			switch(DJAniProgressBar.state) {
				case DJAniProgressBar.PLAY:
					// ★ 在主時間軸會因為不斷地執行play(), 造成聲音無法正常播放,   但若取消play(), 則播放到尾端 or 按下PLAY鍵時就不會播放了
					//		this._parent.play();								因此這行改在 PLAY鍵的處理函式播放
					
					// trace("EF _isPlayToEnd: " + _isPlayToEnd);
					// 問題來源, 完全沒有任何動作, 第一次播放到尾端時會自動停止, 但按下Play第2次播放後, _isPlayToEnd會一直是true。導致第2次之後遇到尾端不停止又重新播放。
					// 所以在state == PLAY時, 就要一直保持_isPlayToEnd = false;	 
					_isPlayToEnd = false;			
					
					// 播放影格動畫時,  應該也要一併更新_newFrame, 否則_newFrame只有在拖曳時才更新會導致在原地mouseUp時, 
					// 播放不斷從舊的影格數播放變成像跳針般的情形  (註解下行測試就可理解)
					this._newFrame = this._parent.currentFrame;
					this.play_btn.visible = false;
					this.pause_btn.visible = true;
					this.play_btn.mouseEnabled = false;
					this.pause_btn.mouseEnabled = true;
					this.stop_btn.mouseEnabled = true;
					this.stop_btn.alpha = 1;
					break;
				
				case DJAniProgressBar.PAUSE:
					// 暫停時也要更新_newFrame 		否則自動播放到尾端 + MOUSE_UP時,  this._newFrame 沒有隨之更新, 其值會等於最後一格-1(ex:180→179), 
					// 這時再一次MOUSE_UP, 就會執行frameGotoAndplay(), state = PLAY, 就變成播放到底後又立刻從頭播放的奇怪情形。
					// 但為何有時不會? 其實是在拖曳時 updatePosition() 會更新 this._newFrame, 但若是改為自動播放就會出問題。(註解下行測試就可理解)
					this._newFrame = this._parent.currentFrame;
					this._parent.stop();
					this.play_btn.visible = true;
					this.pause_btn.visible = false;
					this.play_btn.mouseEnabled = true;
					this.pause_btn.mouseEnabled = false;
					break;
					
				case DJAniProgressBar.STOP:
					this._parent.gotoAndStop(1);
					this.play_btn.visible = true;
					this.pause_btn.visible = false;
					this.play_btn.mouseEnabled = true;
					this.pause_btn.mouseEnabled = false;
					this.stop_btn.mouseEnabled = false;
					this.stop_btn.alpha = 0.5;
					break;	
					
			}
			//trace(DJAniProgressBar.state);
		}
		
		
	}
}