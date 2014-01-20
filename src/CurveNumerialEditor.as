package
{
	import com.bit101.components.Component;
	import com.bit101.components.HUISlider;
	import com.bit101.components.InputText;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.Style;
	import com.bit101.components.TextArea;
	import com.bit101.utils.MinimalConfigurator;
	
	import flash.display.CapsStyle;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.system.System;
	
	[SWF(frameRate="30", width="630", height="420", backgroundColor="#E0E0E0")]
	public class CurveNumerialEditor extends Sprite
	{
		static public const STAGE_W:uint = 630;
		static public const STAGE_H:uint = 420;
		static public const GUI_PANEL_X:uint = 10;
		static public const GUI_PANEL_Y:uint = 10;
		static public const GUI_PANEL_W:uint = 200;
		static public const GUI_PANEL_H:uint = 400;
		static public const CANVAS_X:uint = 220;
		static public const CANVAS_Y:uint = 10;
		static public const CANVAS_W:uint = 400;
		static public const CANVAS_H:uint = 400;
		static private const CURVE_NUMBER:uint = 500;
		
		private var canvas:Shape;
		private var dragP1:DragPoint;
		private var dragP2:DragPoint;
		private var marker:Marker;
		
		//gui
//		public var minXText:InputText;
//		public var maxXText:InputText;
		public var xSegment:InputText;
		public var minYText:InputText;
		public var maxYText:InputText;
		public var yPrecision:NumericStepper;
		public var markerStep:HUISlider;
		public var outputTextArea:TextArea;
		public var p1X:InputText;
		public var p1Y:InputText;
		public var p2X:InputText;
		public var p2Y:InputText;
		
		public function CurveNumerialEditor()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			initGUI();
			init();
		}
		
		private function initGUI():void
		{
			Component.initStage(stage);
			Style.setStyle(Style.DARK);
			
			// GUI panel
			var xml:XML = 	<comps>
								<Panel x= "10" y="10" width="200" height="400">
									<VBox x="5" y="5" spacing="7">
										<HBox>
											<VBox>
												<!-- <Label text="Min X:"/> -->
												<!-- <Label text="Max X:"/> -->
												<Label text="X segment:"/>
												<Label text="Min Y:"/>
												<Label text="Max Y:"/>
												<Label text="Y Precision:"/>
												<Label text="Control Point1 X:"/>
												<Label text="Control Point1 Y:"/>
												<Label text="Control Point2 X:"/>
												<Label text="Control Point2 Y:"/>
											</VBox>
											<VBox spacing="7">
												<!-- <InputText id="minXText" x="80" text="0" restrict="1234567890.-" /> -->
												<!-- <InputText id="maxXText" x="80" text="100" restrict="1234567890.-" /> -->
												<InputText id="xSegment" x="80" text="99" restrict="1234567890" />
												<InputText id="minYText" x="80" text="0" restrict="1234567890.-" />
												<InputText id="maxYText" x="80" text="999" restrict="1234567890.-" />
												<NumericStepper id="yPrecision" x="80" step="1" minimum="0" maximum="20" />
												<InputText id="p1X" x="80" restrict="1234567890.-" event="change:onInputControlPoint" />
												<InputText id="p1Y" x="80" restrict="1234567890.-" event="change:onInputControlPoint" />
												<InputText id="p2X" x="80" restrict="1234567890.-" event="change:onInputControlPoint" />
												<InputText id="p2Y" x="80" restrict="1234567890.-" event="change:onInputControlPoint" />
											</VBox>
										</HBox>
										<HUISlider id="markerStep" label="Marker step:" />
										<HBox>
											<PushButton label="Output" width="90" event="click:onOutputClick" />
											<PushButton label="Copy" width="90" event="click:onCopyClick" />
										</HBox>
										<TextArea id="outputTextArea" width="190" height="140" />
									</VBox>
								</Panel>
							</comps>;
			
			var config:MinimalConfigurator = new MinimalConfigurator(this);
			config.parseXML(xml);
		}
		
		private function init():void
		{
			//drawing canvas
			canvas = new Shape();
			canvas.x = CANVAS_X;
			canvas.y = CANVAS_Y;
			addChild(canvas);
			
			// control dragable point
			dragP1 = new DragPoint();
			dragP1.x = CANVAS_X + CANVAS_W / 2; // !!! canvas坐标
			dragP1.y = CANVAS_Y + CANVAS_H; // !!! canvas坐标
			addChild(dragP1);
			dragP2 = new DragPoint();
			dragP2.x = CANVAS_X + CANVAS_W - CANVAS_W / 2; // !!! canvas坐标
			dragP2.y = CANVAS_Y; // !!! canvas坐标
			addChild(dragP2);
			
			onControlDragPointChange(null);
			
			//position marker
			marker = new Marker();
			addChild(marker);
			
			//listeners
			addEventListener(Event.ENTER_FRAME, draw);
			dragP1.addEventListener(Event.CHANGE, onControlDragPointChange);
			dragP2.addEventListener(Event.CHANGE, onControlDragPointChange);
		}
		
		private function draw(event:Event):void
		{
			// bezier
			var p0:Point = new Point(0, CANVAS_H);
			var p1:Point = new Point(dragP1.x - CANVAS_X, dragP1.y - CANVAS_Y);
			var p2:Point = new Point(dragP2.x - CANVAS_X, dragP2.y - CANVAS_Y);
			var p3:Point = new Point(CANVAS_W, 0);
			var points:Array = new Array();
			points.push(p0, p1, p2, p3);
			
			var up1:Point = new Point(p1.x / CANVAS_W, (CANVAS_H - p1.y) / CANVAS_H);
			var up2:Point = new Point(p2.x / CANVAS_W, (CANVAS_H - p2.y) / CANVAS_H);
			var unit_bezier:UnitBezier = new UnitBezier(up1.x, up1.y, up2.x, up2.y);
			
			// draw canvas
			canvas.graphics.clear();
			canvas.graphics.beginFill(0x999999);
			canvas.graphics.drawRect(0, 0, CANVAS_W, CANVAS_H);
			canvas.graphics.endFill();
			
			// draw x step line
			canvas.graphics.lineStyle(1, 0x707070, 1, false, "normal", CapsStyle.SQUARE);
			var segment:uint = uint(xSegment.text);
			var step:Number = CANVAS_W / segment;
			for (var i:uint = 0; i < segment + 1; i++)
			{
				canvas.graphics.moveTo(i * step, 0);
				canvas.graphics.lineTo(i * step, CANVAS_H);
			}
			
			// draw curve
			canvas.graphics.lineStyle(1, 0x000000, 1, false, "normal", CapsStyle.SQUARE);
			canvas.graphics.moveTo(p0.x, p0.y);
			var t:Number = 1 / CURVE_NUMBER;
			var index:uint = 0;
			while (t < 1)
			{
				var p:Point = BezierCurve.getPoint(t, points);
				canvas.graphics.lineTo(p.x, p.y);
				t += 1 / CURVE_NUMBER;
			}
			canvas.graphics.lineTo(points[points.length - 1].x, points[points.length - 1].y);
			
			// draw control drag point line
			canvas.graphics.lineStyle(1, 0x990000, 1, false, "normal", CapsStyle.SQUARE);
			canvas.graphics.moveTo(p0.x, p0.y);
			canvas.graphics.lineTo(p1.x, p1.y);
			canvas.graphics.moveTo(p3.x, p3.y);
			canvas.graphics.lineTo(p2.x, p2.y);
				
			// draw marker
			var marker_t:Number = unit_bezier.solveCurveX(markerStep.value / 100.0, 0.01); // !!! x轴的单位bezier坐标
			var p:Point = BezierCurve.getPoint(marker_t, points); // !!! canvas坐标
			marker.x = p.x + CANVAS_X; // !!! stage坐标
			marker.y = p.y + CANVAS_Y; // !!! stage坐标
			
			var minY:Number = Number(minYText.text);
			var maxY:Number = Number(maxYText.text);
			marker.label.text = (minY + unit_bezier.sampleCurveY(marker_t) * (maxY - minY)).toFixed(yPrecision.value);
		}
		
		public function onOutputClick(event:MouseEvent):void
		{
			var output:String = new String();
			
			// bezier
			var p1:Point = new Point(dragP1.x - CANVAS_X, dragP1.y - CANVAS_Y);
			var p2:Point = new Point(dragP2.x - CANVAS_X, dragP2.y - CANVAS_Y);
			var up1:Point = new Point(p1.x / CANVAS_W, (CANVAS_H - p1.y) / CANVAS_H);
			var up2:Point = new Point(p2.x / CANVAS_W, (CANVAS_H - p2.y) / CANVAS_H);
			var unit_bezier:UnitBezier = new UnitBezier(up1.x, up1.y, up2.x, up2.y);
			
			var minY:Number = Number(minYText.text);
			var maxY:Number = Number(maxYText.text);
			
			var segment:uint = uint(xSegment.text);
			var x:Number = 0;
			var step:Number = 1.0 / (segment - 1);
			for (var i:uint = 0; i < segment; i++)
			{
				output += (minY + unit_bezier.solve(x, 0.01) * (maxY - minY)).toFixed(yPrecision.value) + "\n";
				x += step;
			}
			
			outputTextArea.text = output;
		}
		
		public function onCopyClick(event:MouseEvent):void
		{
			System.setClipboard(outputTextArea.text);
		}
		
		public function onInputControlPoint(event:Event):void
		{
			dragP1.x = Number(p1X.text) * CANVAS_W + CANVAS_X; // !!! stage坐标
			dragP1.y = (CANVAS_H - Number(p1Y.text) * CANVAS_H) + CANVAS_Y; // !!! stage坐标
			dragP2.x = Number(p2X.text) * CANVAS_W + CANVAS_X; // !!! stage坐标
			dragP2.y = (CANVAS_H - Number(p2Y.text) * CANVAS_H) + CANVAS_Y; // !!! stage坐标
		}
		
		public function onControlDragPointChange(event:Event):void
		{
			p1X.text = ((dragP1.x - CANVAS_X) / CANVAS_W).toFixed(2); // !!! 单位bezier坐标
			p1Y.text = ((CANVAS_H - (dragP1.y - CANVAS_Y)) / CANVAS_H).toFixed(2); // !!! 单位bezier坐标
			p2X.text = ((dragP2.x - CANVAS_X) / CANVAS_W).toFixed(2); // !!! 单位bezier坐标
			p2Y.text = ((CANVAS_H - (dragP2.y - CANVAS_Y)) / CANVAS_H).toFixed(2); // !!! 单位bezier坐标
		}
		
	}
}
