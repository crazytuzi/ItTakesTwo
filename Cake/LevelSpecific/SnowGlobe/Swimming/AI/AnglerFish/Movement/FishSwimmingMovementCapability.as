import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Animation.FishAnimationComponent;

class UFishSwimmingMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Swimming");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 20.f;

    UFishBehaviourComponent BehaviourComp;
	UFishAnimationComponent AnimComp;
	UFishComposableSettings Settings;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedFloat ObstructionAvoidanceFactor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        BehaviourComp = UFishBehaviourComponent::Get(Owner);
		AnimComp = UFishAnimationComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);
		ObstructionAvoidanceFactor.SnapTo(0.f);
		AccRotation.SnapTo(Owner.ActorRotation);

		ensure((BehaviourComp != nullptr) && (AnimComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"FishSwimming");

		// Actual movement is only calculated on control side, with remote side consuming crumbs
		if (HasControl())
		{
			// Turn towards destination, while accelerating forwards
			FVector Velocity = MoveComp.GetVelocity();
			float Acceleration = BehaviourComp.MovementAcceleration;
			if (Acceleration > 0.f)
			{
				FVector Destination = BehaviourComp.GetMoveDestination();
				FVector ToDestDir = (Destination - Owner.GetActorLocation()).GetSafeNormal();
				AccRotation.AccelerateTo(ToDestDir.Rotation(), BehaviourComp.MovementTurnDuration, DeltaSeconds);	

				FVector AccelerationDir = AccRotation.Value.Vector();
				if (MoveComp.PreviousImpacts.ForwardImpact.bBlockingHit || MoveComp.PreviousImpacts.DownImpact.bBlockingHit)
					ObstructionAvoidanceFactor.SnapTo(0.1f);
				else
					ObstructionAvoidanceFactor.AccelerateTo(0.f, 0.1f, DeltaSeconds);
				AccelerationDir += FVector(0.f, 0.f, ObstructionAvoidanceFactor.Value);
				
				FVector AccleratedVelocity = AccelerationDir * Acceleration;
				FVector Dampening = Velocity * 1.3f;
				Velocity += (AccleratedVelocity - Dampening) * DeltaSeconds;

#if EDITOR
				//BehaviourComp.bHazeEditorOnlyDebugBool = true;
				if (BehaviourComp.bHazeEditorOnlyDebugBool)
				{
					System::DrawDebugLine(Owner.ActorLocation, Destination, FLinearColor::White, 0.f, 100.f);
					System::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + AccelerationDir * 8000.f, FLinearColor::Green, 0.f, 120.f);
					if (ObstructionAvoidanceFactor.Value > 0.01f)
						System::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + AccRotation.Value.Vector() * 8000.f, FLinearColor::Red, 0.f, 120.f);
				}
#endif
			}
			else
			{
				// No acceleration, just drift to a stop
				FVector Dampening = Velocity * 4.f;
				ObstructionAvoidanceFactor.AccelerateTo(0.f, 0.1f, DeltaSeconds);
				Velocity -= Dampening * DeltaSeconds;

				// Level out steep pitch and roll when floating
				FRotator TargetRotation = Owner.ActorRotation;
				TargetRotation.Pitch = FMath::Clamp(FRotator::NormalizeAxis(TargetRotation.Pitch), -10.f, 0.f);
				TargetRotation.Roll = 0.f;
				AccRotation.AccelerateTo(TargetRotation, 10.f, DeltaSeconds);	
			}

			// Change world up so we'll move up/down properly
			Owner.ChangeActorWorldUp(GetSwimmingWorldUp(AccRotation.Value));

			MoveComp.SetTargetFacingRotation(AccRotation.Value); 
			MoveData.ApplyVelocity(Velocity);
			MoveData.ApplyTargetRotationDelta();

			// We expect behaviours to set acceleration each tick, or we will just drift to a stop
			BehaviourComp.MovementAcceleration = 0.f;
		}
		else
		{
			// Remote, follow them crumbsies
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaSeconds, ConsumedParams);

			// Change world up so we'll move up/down properly
			Owner.ChangeActorWorldUp(GetSwimmingWorldUp(ConsumedParams.Rotation));

			FHazeReplicatedFrameMovementSettings ReplicationSettings;
			ReplicationSettings.bUseReplicatedWorldUp = false;
			ReplicationSettings.ReplicatedRotationSmoothSpeed = 10.f;
			MoveData.ApplyConsumedCrumbData(ConsumedParams, ReplicationSettings);

			// Accelerated rotation should be prepped if we're switching control side
			AccRotation.SnapTo(ConsumedParams.Rotation);	
		}

		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
		MoveCharacter(MoveData, FeatureName::Swimming);
		CrumbComp.LeaveMovementCrumb();
	}

	FQuat FwdToUp = FQuat(FRotator(90.f, 0.f, 0.f));
	FVector GetSwimmingWorldUp(const FRotator& ForwardRot)
	{
		FRotator ModifiedForward = ForwardRot;
		ModifiedForward.Pitch = FMath::ClampAngle(ForwardRot.Pitch, -Settings.MaxSwimPitchDown, Settings.MaxSwimPitchUp);
		ModifiedForward.Roll = 0.f;
		FRotator UpRot = FRotator(FQuat(ModifiedForward) * FwdToUp);
		return UpRot.Vector();
	}
};
