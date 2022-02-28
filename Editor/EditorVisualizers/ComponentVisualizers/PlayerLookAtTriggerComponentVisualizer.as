import Vino.Triggers.PlayerLookAtTriggerComponent;

class UPlayerLookAtTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UPlayerLookAtTriggerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UPlayerLookAtTriggerComponent LookAtComp = Cast<UPlayerLookAtTriggerComponent>(Component);
		if (LookAtComp == nullptr)
			return;		

		if (LookAtComp.TriggerVolume != nullptr)
			DrawDashedLine(LookAtComp.WorldLocation, LookAtComp.TriggerVolume.ActorLocation, FLinearColor::Yellow, 10.f);
		
		// Range
		FVector ViewLoc = Editor::GetEditorViewLocation();
		FLinearColor RangeColor = (LookAtComp.WorldLocation.IsNear(ViewLoc, LookAtComp.Range)) ? FLinearColor::Green : FLinearColor::Red;
		DrawWireSphere(LookAtComp.WorldLocation, LookAtComp.Range, RangeColor, 10.f, 12);
		
		// View center fraction
		float DrawDist = 100.f;
		FRotator ViewRot = Editor::GetEditorViewRotation();
		FVector ViewFwd = ViewRot.Vector();
		FVector ViewRight = FRotator(0.f, 90.f, 0.f).Compose(ViewRot).Vector();
		FVector2D ViewRes = Editor::GetEditorViewResolution();
		float AspectRatio = ViewRes.X / ViewRes.Y;
		if (FMath::IsNaN(AspectRatio))
			AspectRatio = 16.f / 9.f;
		float VerticalFOV = FMath::Clamp(Editor::GetEditorViewFOV(), 5.f, 179.f);
		float HorizontalFOV = FMath::Clamp(FMath::RadiansToDegrees(2.f * FMath::Atan(FMath::Tan(FMath::DegreesToRadians(VerticalFOV * 0.5)) * AspectRatio)), 5.f, 179.f);
		float Height = DrawDist * FMath::Tan(FMath::DegreesToRadians(VerticalFOV * 0.5f));
		float Width = DrawDist * FMath::Tan(FMath::DegreesToRadians(HorizontalFOV * 0.5f));
		FVector DrawPlaneCenter = ViewLoc + ViewFwd * DrawDist;

		// Are we looking close enough?
		bool bLookingAt = false;
		if (ViewFwd.DotProduct(LookAtComp.WorldLocation - ViewLoc) > 0.f) // TODO: This is incorrect if view > 90
		{
			FVector DrawPlaneVec = FTransform(ViewRot, DrawPlaneCenter).InverseTransformPosition(FMath::LinePlaneIntersection(ViewLoc, LookAtComp.WorldLocation, DrawPlaneCenter, ViewFwd));
			FVector2D DrawPlaneFraction = FVector2D(DrawPlaneVec.Y / Width, DrawPlaneVec.Z / Height);
			if (DrawPlaneFraction.SizeSquared() < FMath::Square(LookAtComp.ViewCenterFraction))
				bLookingAt = true; 

			//FVector Origin = DrawPlaneCenter;
			FVector Origin = FMath::LinePlaneIntersection(LookAtComp.WorldLocation, ViewLoc, DrawPlaneCenter, ViewFwd);
			FLinearColor ViewColor = bLookingAt ?  FLinearColor::Green : FLinearColor::Red;// FLinearColor(1.f, 0.5f, 0.f);
			DrawEllipse(Origin, FVector2D(Width, Height) * LookAtComp.ViewCenterFraction, ViewColor, 0.2f, 0.f, ViewFwd, ViewRight);
		}
		DrawPoint(DrawPlaneCenter, FLinearColor::Purple, 8.f);
	}
};