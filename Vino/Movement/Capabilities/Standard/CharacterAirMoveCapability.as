
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Vino.Movement.Helpers.BurstForceStatics;
import Vino.Movement.MovementSettings;
import Vino.Audio.Movement.PlayerMovementAudioComponent;

class UCharacterAirMoveCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::AirMovement);
	default CapabilityTags.Add(MovementSystemTags::Falling);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 175;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	// Internal Variables
	FVector AccumulatedForces = FVector::ZeroVector;
	AHazePlayerCharacter Player;
	FVector CurrentBlendSpaceValues = FVector::ZeroVector;
	UCameraShakeBase CurrentCameraShake;
	UPlayerHazeAkComponent PlayerHazeAkComp;
	UPlayerMovementAudioComponent AudioMoveComp;

	FName DeactiationReason = NAME_None;

	FName WallImpactName = n"WallImpact";

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(CharacterOwner);
		PlayerHazeAkComp = UPlayerHazeAkComponent::Get(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!ShouldBeGrounded())
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

 		if(DeactiationReason != NAME_None)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentBlendSpaceValues = FVector::ZeroVector;

		UMovementSettings::SetVerticalForceAirPushOffThreshold(Owner, 0.f, Instigator = this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.ClearSettingsByInstigator(this);

		if (CurrentCameraShake != nullptr && Player != nullptr)
		{
			Player.StopCameraShake(CurrentCameraShake, true);
			CurrentCameraShake = nullptr;
		}

		if(!AccumulatedForces.IsNearlyZero())
		{
			AccumulatedForces = FVector::ZeroVector;
		}

		FVector ImpactDirection = FVector::ZeroVector;
		if(DeactiationReason == WallImpactName)
		{
			const float CollisionSpeed = MoveComp.GetVelocity().Size2D(MoveComp.WorldUp);
			FVector ImpactForce = FVector::ZeroVector;
			MoveComp.WallWasHit(ImpactDirection);
		
		}
		DeactiationReason = NAME_None;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())
		{
		 	if(!HasControl())
		 	{
		 		//DeactiationReason = WallImpactName;
		 		// if (!SyncMovementComp.CanTriggerCurrentCrumbAsAction(DeactiationReason))
		 		// {
				 	DeactiationReason = NAME_None;
		 		// }
		 	}
			else
			{
				const float CollisionSpeed = MoveComp.GetVelocity().Size2D(MoveComp.WorldUp);
				if(CollisionSpeed > MoveComp.HorizontalAirSpeed * 2.0f)
				{
					FVector WallCollisionNormal = FVector::ZeroVector;
					if(MoveComp.WallWasHit(WallCollisionNormal))
					{
						DeactiationReason = WallImpactName;
					}
				}
			}
		}
	}

	void MakeFrameMovementData(FHazeFrameMovement& FrameMoveData, float DeltaTime)
	{
		if(HasControl() || Player.MovementSyncronizationIsBlocked())
		{
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float MoveSpeed = MoveComp.HorizontalAirSpeed;
			
			FrameMoveData.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, Input, MoveSpeed));
			FrameMoveData.ApplyAndConsumeImpulses();
			FrameMoveData.ApplyActorVerticalVelocity();
			FrameMoveData.ApplyGravityAcceleration();
			FrameMoveData.ApplyTargetRotationDelta();
			FrameMoveData.FlagToMoveWithDownImpact();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMoveData.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMoveData.OverrideStepUpHeight(20.f);
		FrameMoveData.OverrideStepDownHeight(0.f);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"AirMovement");
		MakeFrameMovementData(FinalMovement, DeltaTime); 

		const FVector SteeringVector = GetAttributeVector(AttributeVectorNames::MovementDirection);

		#if !RELEASE
		if(IsDebugActive())
		{
			float Radius = 0;
			float HalfHeight = 0;
			CharacterOwner.GetCollisionSize(Radius, HalfHeight);
			FVector DebugLocation = CharacterOwner.GetActorLocation() + (MoveComp.GetWorldUp() * HalfHeight);
			System::DrawDebugArrow(DebugLocation, DebugLocation + (SteeringVector * 200.f), LineColor = FLinearColor::Blue, Thickness = 4.f);
		}
		#endif

		FVector NewBlendSpaceValues = FVector::ZeroVector;
		NewBlendSpaceValues.Y = FMath::Lerp(-100.f, 100.f, (SteeringVector.X + 1.f) * 0.5f);
		NewBlendSpaceValues.X = FMath::Lerp(-100.f, 100.f, (SteeringVector.Y + 1.f) * 0.5f);

		NewBlendSpaceValues = Owner.GetActorRotation().UnrotateVector(NewBlendSpaceValues);
		CurrentBlendSpaceValues = FMath::VInterpConstantTo(CurrentBlendSpaceValues, NewBlendSpaceValues, DeltaTime, 300.f);

		Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceX, CurrentBlendSpaceValues.X);
		Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceY, CurrentBlendSpaceValues.Y);
		
		MoveCharacter(FinalMovement, FeatureName::AirMovement);
		CrumbComp.LeaveMovementCrumb();

		UpdateAirCameraShake();
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return "";
	}

	void UpdateAirCameraShake()
	{
		// const FVector ConstrainedVelocity = Math::ConstrainVectorToDirection(MoveComp.Velocity, MoveComp.WorldUp);
		// const float ConstrainedVelocitySize = ConstrainedVelocity.Size();

		// if (MoveComp.CurrentAirTime > 1.0f && ConstrainedVelocitySize >= MoveComp.MaxFallSpeed * 0.3f && Player != nullptr && ConstrainedVelocity.GetSafeNormal().DotProduct(MoveComp.WorldUp) < 0.f)
		// {
		// 	if (CurrentCameraShake == nullptr)
		// 	{
		// 		CurrentCameraShake = Player.PlayCameraShake(CameraShake, 1.75f);
		// 	}
		// }
		// else
		// {
		// 	if (CurrentCameraShake != nullptr)
		// 	{
		// 		Player.StopCameraShake(CurrentCameraShake, true);
		// 		CurrentCameraShake = nullptr;
		// 	}
		// }

	}
};
