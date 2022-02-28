import Vino.Camera.Components.CameraSplineFollowerComponent;

class UCameraSplineFollowerComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UCameraSplineFollowerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
#if EDITOR
        UCameraSplineFollowerComponent SplineFollowerComp = Cast<UCameraSplineFollowerComponent>(Component);
        if (!ensure(SplineFollowerComp != nullptr))
            return;

        if (SplineFollowerComp.CameraSpline == nullptr)
            return;

        UHazeCameraComponent Camera = UHazeCameraComponent::Get(SplineFollowerComp.GetOwner());
        if (Camera == nullptr)
            return;

        // Show how ends of guide and camera spline map
        if (SplineFollowerComp.GuideSpline != nullptr)       
        {
            DrawDashedLine(SplineFollowerComp.CameraSpline.GetLocationAtTime(0, ESplineCoordinateSpace::World), 
                           SplineFollowerComp.GuideSpline.GetLocationAtTime(0, ESplineCoordinateSpace::World),
                           FLinearColor::Green, 20);
            DrawDashedLine(SplineFollowerComp.CameraSpline.GetLocationAtTime(SplineFollowerComp.CameraSpline.Duration, ESplineCoordinateSpace::World), 
                           SplineFollowerComp.GuideSpline.GetLocationAtTime(SplineFollowerComp.GuideSpline.Duration, ESplineCoordinateSpace::World), 
                           FLinearColor::Yellow, 20);
        }

        // Show clamps at visualized location
        FVector VisCamLoc = Camera.GetWorldLocation();
        float VisDistAlongSpline = SplineFollowerComp.PreviewSplineFraction * SplineFollowerComp.CameraSpline.GetSplineLength();
        FHazeCameraClampSettings Clamps = Camera.ClampSettings;
        if (Clamps.IsUsed())
        {
            SplineFollowerComp.ModifyClamps(VisDistAlongSpline, Clamps);
            if (Clamps.bUseClampYawLeft || Clamps.bUseClampYawRight)
            {
                float ArcAngle = Clamps.ClampYawLeft + Clamps.ClampYawRight;
                if (ArcAngle < 360.f)
                {
            		float ArcCenter = Clamps.CenterOffset.Yaw;
	    	        ArcCenter += 0.5f * ArcAngle - Clamps.ClampYawLeft;
                    DrawArc(VisCamLoc, ArcAngle, 1000.f, FRotator(0.f, ArcCenter, 0.f).Vector(), FLinearColor::Yellow, 2.f, FVector::UpVector);
                }
            }
            if (Clamps.bUseClampPitchDown || Clamps.bUseClampPitchUp)
            {
                float ArcAngle = Clamps.ClampPitchDown + Clamps.ClampPitchUp;
                if (ArcAngle < 360.f)
                {
            		float ArcCenter = Clamps.CenterOffset.Pitch;
	    	        ArcCenter += 0.5f * ArcAngle - Clamps.ClampPitchDown;
                    FVector CenterDir = FRotator(ArcCenter, Clamps.CenterOffset.Yaw, 0.f).Vector();
                    FVector Normal = FVector::UpVector.CrossProduct(CenterDir);
                    DrawArc(VisCamLoc, ArcAngle, 1000.f, CenterDir, FLinearColor(1.f,0.2f,0.f), 2.f, Normal);
                }
            }
        }

#endif //EDITOR
    }   
} 

