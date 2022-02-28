import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.Dandelion;
import Vino.Movement.Components.MovementComponent;

#if EDITOR
const FConsoleVariable CVar_DebugDrawDandelionPhysics("Dandelion.DebugDrawPhysics", 0);
#endif // EDITOR

// This thing moves up and down, and sideways

class UDandelionPhysicsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	//float VerticalDelta = 0.0f;
	float TargetHeight = 0.0f;
	float LaunchTime = 1.0f;

	bool bIsLaunching = false;

	FHazeAcceleratedFloat CurrentHeight;
	//FVector CurrentVelocity;

	ADandelion Dandelion;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	UDandelionComponent DandelionComp;

	UDandelionSettings Settings;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Dandelion = Cast<ADandelion>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		DandelionComp = UDandelionComponent::Get(Dandelion.OwnerPlayer);
		Settings = Dandelion.DandelionSettings;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Dandelion.bDandelionActive)
		{
			return EHazeNetworkActivation::DontActivate;
		}
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Dandelion.HorizontalVelocity = FVector::ZeroVector;
		Dandelion.VerticalDelta = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Dandelion.bDandelionActive)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement ThisFrameMove = MoveComp.MakeFrameMovement(n"DandelionPhysicsCapability");
		MakeFrameMovementData(ThisFrameMove, DeltaTime);
		MoveComp.Move(ThisFrameMove);
		CrumbComp.LeaveMovementCrumb();
	}

	void MakeFrameMovementData(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		if(HasControl())
		{
			if(!FMath::IsNearlyZero(Dandelion.PendingLaunchHeight))
			{
				Dandelion.VerticalDelta = Dandelion.PendingLaunchHeight;
				bIsLaunching = true;
				CurrentHeight.Value = Dandelion.ActorLocation.Z;
				TargetHeight = Dandelion.ActorLocation.Z + Dandelion.PendingLaunchHeight;
				LaunchTime = Dandelion.PendingLaunchTime;
				Dandelion.PendingLaunchHeight = 0.0f;
			}

			if(MoveComp.UpHit.bBlockingHit)
			{
				bIsLaunching = false;
				Dandelion.VerticalDelta = 0.0f;
			}

			if(!bIsLaunching)
			{
				Dandelion.VerticalDelta -= Settings.FallSpeedAcceleration * DeltaTime;
				Dandelion.VerticalDelta = FMath::Max(Dandelion.VerticalDelta, -Settings.FallSpeedMaximum);
				FrameMove.ApplyDelta(FVector(0.0f, 0.0f, Dandelion.VerticalDelta) * DeltaTime);
			}
			else
			{
				CurrentHeight.AccelerateTo(TargetHeight, LaunchTime, DeltaTime);

				if(FMath::IsNearlyEqual(CurrentHeight.Value, TargetHeight, 1.0f))
				{
					bIsLaunching = false;
				}

				Dandelion.VerticalDelta = CurrentHeight.Value - Dandelion.ActorLocation.Z;
				FrameMove.ApplyDelta(FVector(0.0f, 0.0f, Dandelion.VerticalDelta));
			}

			const FVector MovementDirection = Dandelion.WantedDirection;
			const FVector Acceleration = MovementDirection * Settings.HorizontalAcceleration;
			
			Dandelion.HorizontalVelocity *= FMath::Pow(Settings.HorizontalDrag, DeltaTime);
			Dandelion.HorizontalVelocity += Acceleration * DeltaTime;

			if(Dandelion.HorizontalVelocity.Size2D() >= Settings.HorizontalVelocityMaximum)
			{
				Dandelion.HorizontalVelocity = Dandelion.HorizontalVelocity.GetSafeNormal2D() * Settings.HorizontalVelocityMaximum;
			}
#if EDITOR

			if(CVar_DebugDrawDandelionPhysics.GetInt() == 1)
			{
				const FString DebugString_CurrentFallSpeed = "FallSpeed: " + Dandelion.VerticalDelta;
				System::DrawDebugString(Owner.ActorLocation + (FVector::UpVector * 200.0f), DebugString_CurrentFallSpeed, Owner, FLinearColor::Green);
			}

#endif // EDITOR

			FrameMove.ApplyDelta(Dandelion.HorizontalVelocity * DeltaTime);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
	 		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.OverrideStepUpHeight(0.f);
		FrameMove.OverrideStepDownHeight(0.f);
	}
}
