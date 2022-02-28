import Cake.LevelSpecific.SnowGlobe.SnowFolk.ConnectedHeightSplineFollowerComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrolTripComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrolRepelComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.Movement.MovementSystemTags;
import Peanuts.Audio.VO.PatrolActorAudioComponent;

import void RegisterToyPatrol(AToyPatrol) from "Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrolManager";
import void UnregisterToyPatrol(AToyPatrol) from "Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrolManager";

class UToyPatrolVisualizerComponent : UActorComponent { }
class UToyPatrolVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UToyPatrolVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        AToyPatrol Toy = Cast<AToyPatrol>(Component.Owner);
        UConnectedHeightSplineFollowerComponent FollowerComp = Toy.SplineFollowerComponent;
        UConnectedHeightSplineComponent Spline = FollowerComp.Spline;

        if (Toy == nullptr || Spline == nullptr)
            return;

		float InitialDistance = Spline.GetDistanceAlongSplineAtWorldLocation(Toy.ActorLocation);
		FVector InitialLocation = Spline.GetLocationAtDistanceAlongSpline(InitialDistance, ESplineCoordinateSpace::World);
		DrawDashedLine(Toy.ActorLocation, InitialLocation);
		DrawPoint(InitialLocation, Size = 20.f);

		float PointDistance = 50.f;
		FVector PointOffset = FVector::UpVector * 10.f;
		int NumPoints = Spline.SplineLength / PointDistance;
		for (int i = 0; i < NumPoints; ++i)
		{
			float CurrentDistance = FMath::Clamp(i * PointDistance,
				0.f, Spline.SplineLength);

			FVector Point = Spline.GetTransformAtDistanceAndOffset(CurrentDistance,
				Toy.GetSineOffset(CurrentDistance)).Location;

			float NextDistance = FMath::Clamp((i + 1) * PointDistance,
				0.f, Spline.SplineLength);

			FVector NextPoint = Spline.GetTransformAtDistanceAndOffset(NextDistance,
				Toy.GetSineOffset(NextDistance)).Location;

			DrawLine(Point + PointOffset, NextPoint + PointOffset, FLinearColor::DPink, 10.f, true);
		}
    }
}

class AToyPatrol : AHazeCharacter
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default Mesh.bComponentUseFixedSkelBounds = true;
	default CapsuleComponent.RelativeLocation = FVector::UpVector * 76.f;
	default CapsuleComponent.CapsuleHalfHeight = 76.f;
	default CapsuleComponent.CapsuleRadius = 36.f;
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default CapsuleComponent.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UConnectedHeightSplineFollowerComponent SplineFollowerComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default EHazeCrumbSyncIntervalType::Slow;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactCallback;

	UPROPERTY(DefaultComponent)
	UToyPatrolTripComponent TripComponent;

	UPROPERTY(DefaultComponent)
	UToyPatrolRepelComponent RepelComponent;

	UPROPERTY(DefaultComponent)
	UPatrolActorAudioComponent AudioPatrolComp;

	UPROPERTY(DefaultComponent)
	UToyPatrolVisualizerComponent Visualizer;

	UPROPERTY(Category = "Toy Patrol")
	float MovementSpeed = 260.f;

	// Avoidance is simply movemenet speed increase/decrease, no need to disable currently
	// UPROPERTY(Category = "Toy Patrol")
	// bool bUseAvoidance = true;

	UPROPERTY(Category = "Toy Patrol")
	float PauseDuration = 2.3f;

	UPROPERTY(Category = "Toy Patrol")
	float TiltAngle = 30.f;

	UPROPERTY(Category = "Toy Patrol|Offset")
	float OffsetPhase = 0.f;

	UPROPERTY(Category = "Toy Patrol|Offset")
	float OffsetFrequency = 0.15f;

	UPROPERTY(Category = "Toy Patrol|Offset", Meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float OffsetScale = 1.f;

	UPROPERTY(Category = "Toy Patrol|Offset")
	float OffsetCoefficient = 0.15f;

	UPROPERTY(Category = "Toy Patrol|Interpolation")
	float SpeedInterpRate = 5.f;

	UPROPERTY(Category = "Toy Patrol|Interpolation")
	float RotationInterpRate = 10.f;

	UPROPERTY(Category = "Toy Patrol|Interpolation")
	float TransitionLerpTime = 5.f;

	UPROPERTY(Category = "Toy Patrol|Capabilities")
	UHazeCapabilitySheet CapabilitySheet;

	UPROPERTY(Category = "Toy Patrol|Capabilities")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	float EntryDistance;
	float EntryOffset;
	float AvoidanceOffset;
	float AvoidanceSpeedScale;
	float AccumulativeOffset;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SplineFollowerComponent.SetSplineActorSpline();

		if (SplineFollowerComponent.Spline != nullptr)
			SplineFollowerComponent.SetDistanceAndOffsetAtWorldLocation(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapabilitySheet(CapabilitySheet);
		Capability::AddPlayerCapabilitySheetRequest(PlayerCapabilitySheet);

		if (SplineFollowerComponent.Spline != nullptr)
		{
			SplineFollowerComponent.SetDistanceAndOffsetAtWorldLocation(ActorLocation);
			EntryDistance = SplineFollowerComponent.DistanceOnSpline;
			EntryOffset = SplineFollowerComponent.Offset;
		}

		ImpactCallback.OnActorForwardImpacted.AddUFunction(this, n"HandleActorForwardImpacted");

		RegisterToyPatrol(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilitySheetRequest(PlayerCapabilitySheet);

		UnregisterToyPatrol(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		RegisterToyPatrol(this);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		UnregisterToyPatrol(this);
		return false;
	}

	float GetSineOffset(float Distance)
	{
		float SplineLength = SplineFollowerComponent.Spline.SplineLength;
		float SineOffset = FMath::Sin(AccumulativeOffset + (OffsetFrequency * PI * 2.f / SplineLength) * (Distance + OffsetPhase)) * OffsetScale;

		return SineOffset;
	}

	UFUNCTION()
	void HandleActorForwardImpacted(AHazeActor Actor, const FHitResult& HitResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if (Player != nullptr && Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
		{
			FVector ToPlayer = Actor.ActorLocation - ActorLocation;
			FVector ForwardVector = HitResult.Normal.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			FVector RightVector = ForwardVector.CrossProduct(FVector::UpVector);

			if (RightVector.DotProduct(ToPlayer.GetSafeNormal()) > 0.f) 
				RightVector *= -1.f;
			
			TripComponent.Trip(Actor, RightVector);
		}
	}
}