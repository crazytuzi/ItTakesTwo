import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingSettings;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticIceSkatingBoostGateComponent;

#if EDITOR
class UIceSkatingMagnetBoostGateVisualizerComponent : UActorComponent { } 

class UIceSkatingMagnetBoostGateVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIceSkatingMagnetBoostGateVisualizerComponent::StaticClass();
	FIceSkatingAirSettings AirSettings;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		AIceSkatingMagnetBoostGate Gate = Cast<AIceSkatingMagnetBoostGate>(Component.Owner);
        if (!ensure(Gate != nullptr))
            return;

        // Draw magnet spheres
		DrawWireSphere(Gate.RedMagnet.WorldLocation, Gate.ActivateRadius, FLinearColor::Green, Thickness = 2.f, Segments = 20);
		DrawWireSphere(Gate.RedMagnet.WorldLocation, Gate.TargetRadius, FLinearColor::Yellow, Thickness = 2.f, Segments = 20);
		DrawWireSphere(Gate.RedMagnet.WorldLocation, Gate.VisibleRadius, FLinearColor::Red, Thickness = 2.f, Segments = 20);

		// Draw launch trajectory
        FVector Velocity = Gate.ArrowComp.ForwardVector * Gate.ExitSpeed;

		// Get points
		FTrajectoryPoints VisPoints = CalculateTrajectory(Gate.ArrowComp.WorldLocation, Gate.VisLength, Velocity, AirSettings.Gravity, 1.f, AirSettings.MaxFallSpeed); 

		// Draw lines and stars!
		for(int i=0; i<VisPoints.Num(); ++i)
		{
			// If this is the last point, we cant draw a line to the next one
			if (i < VisPoints.Num() - 1)
			{
				FVector Position = VisPoints.Positions[i];
				FVector NextPosition = VisPoints.Positions[i + 1];
				DrawLine(Position, NextPosition, FLinearColor::Green, 10.f);
			}
		}

		// Draw vision cone
		float Angle = Gate.ActivateConeAngle * DEG_TO_RAD * 0.5f;
		FVector Dir_Right(-FMath::Cos(Angle), FMath::Sin(Angle), 0.f);
		FVector Dir_Left(-FMath::Cos(Angle), -FMath::Sin(Angle), 0.f);

		FTransform Transform = Gate.RedMagnet.WorldTransform;
		FVector Loc = Transform.Location;
		DrawLine(Loc, Loc + Transform.TransformVector(Dir_Right) * 5000.f, FLinearColor::Yellow, 5.f);
		DrawLine(Loc, Loc + Transform.TransformVector(Dir_Left) * 5000.f, FLinearColor::Yellow, 5.f);
	}
}
#endif

event void FOnMagnetBoostGateLaunched(AHazePlayerCharacter LaunchedPlayer);

class UHazeIceSkatingMagnetBoostMesh : UStaticMeshComponent
{
	// This component is not disabled
	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		return true;
	}
}

class AIceSkatingMagnetBoostGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UHazeIceSkatingMagnetBoostMesh Mesh;
	default Mesh.SetRelativeScale3D(FVector(1.75f));
	default Mesh.bGenerateOverlapEvents = true;
	default Mesh.SetCastShadow(false);

	UPROPERTY(DefaultComponent)
	UMagneticIceSkatingBoostGateComponent RedMagnet;

	UPROPERTY(DefaultComponent)
	UMagneticIceSkatingBoostGateComponent BlueMagnet;

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bAutoDisable = true;
	default Disable.AutoDisableRange = 10000.f;
	default Disable.bActorIsVisualOnly = true;

#if EDITOR
	UPROPERTY(DefaultComponent, NotVisible)
	UIceSkatingMagnetBoostGateVisualizerComponent VisualizerComp;

	UPROPERTY(Category = "Trajectory")
	float VisLength = 15000.f;
#endif

	// Target speed to reach when accelerating towards the gate
	UPROPERTY(Category = "IceSkating")
	float TargetSpeed = 4500.f;

	// How fast the target speed is reached (higher = faster)
	UPROPERTY(Category = "IceSkating")
	float AccelerationCoefficient = 1.7f;

	// How fast the player should turn to align themselves when using the gate
	UPROPERTY(Category = "IceSkating")
	float TurningCoefficient = 9.8f;

	// After passing the gate, the players will be set to have this speed
	// If ExitSpeed < 0, the speed wont be altered going out of the gate
	UPROPERTY(Category = "IceSkating")
	float ExitSpeed = 5000.f;

	UPROPERTY(Category = "IceSkating")
	float InputPauseDuration = 0.f;

	UPROPERTY(Category = "Magnet")
	float ActivateConeAngle = 95.f;

	UPROPERTY(Category = "Magnet")
	float ActivateRadius = 8000.f;

	UPROPERTY(Category = "Magnet")
	float TargetRadius = 9000.f;

	UPROPERTY(Category = "Magnet")
	float VisibleRadius = 10000.f;

	int32 MagnetInteractingPlayerCount;

	UPROPERTY()
	FOnMagnetBoostGateLaunched OnLaunched;
 
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		RedMagnet.InitializeDistance(EHazeActivationPointDistanceType::Targetable, ActivateRadius);
		RedMagnet.InitializeDistance(EHazeActivationPointDistanceType::Selectable, TargetRadius);
		RedMagnet.InitializeDistance(EHazeActivationPointDistanceType::Visible, VisibleRadius);
		RedMagnet.ActivateConeAngle = ActivateConeAngle;

		BlueMagnet.InitializeDistance(EHazeActivationPointDistanceType::Targetable, ActivateRadius);
		BlueMagnet.InitializeDistance(EHazeActivationPointDistanceType::Selectable, TargetRadius);
		BlueMagnet.InitializeDistance(EHazeActivationPointDistanceType::Visible, VisibleRadius);
		BlueMagnet.ActivateConeAngle = ActivateConeAngle;

		FVector ExitForward = ActorForwardVector;

		// Calculate the exit forward vector based on the ground this gate is standing on
		//	(since we dont want to launch up or down relative to the ground, causing a bit of weirdness)
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(this);

		FHitResult Hit;

		if (System::LineTraceSingle(
			RedMagnet.WorldLocation, ActorLocation - ActorUpVector * 200.f,
			ETraceTypeQuery::Visibility, false, IgnoreActors,
			EDrawDebugTrace::None, Hit, true))
		{
			// Find the forward on this ground-normal
			ExitForward = Math::ConstrainVectorToSlope(ExitForward, Hit.Normal, FVector::UpVector);
			ExitForward.Normalize();
			ArrowComp.SetWorldLocation(Hit.Location);
		}
		else
		{
			ArrowComp.SetRelativeLocation(FVector::ZeroVector);
		}

		ArrowComp.SetWorldRotation(Math::MakeRotFromX(ExitForward));
	}

	FVector GetImpulseForward() property
	{
		return ArrowComp.ForwardVector;
	}

	FVector GetImpulseLocation() property
	{
		return ArrowComp.WorldLocation;
	}
}