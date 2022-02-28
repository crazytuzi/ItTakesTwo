import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingStatics;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingSettings;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.Capabilities.Crouch.CharacterCrouchComponent;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Vino.Movement.Capabilities.Sliding.SlidingNames;
import Rice.Math.MathStatics;

class UCharacterSlidingCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Grounded);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::SlopeSlide);
	default CapabilityTags.Add(MovementSystemTags::Sprint);
	
	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 110;

	AHazePlayerCharacter Player;
	UCharacterSlidingComponent SlidingComp;
	UCharacterCrouchComponent CrouchComp;
	USlidingSettings SlidingSettings;

	UHazeAkComponent HazeAkComp;
	UPlayerMovementAudioComponent AudioMoveComp;
	FHazeAudioEventInstance MaterialAudioEventInstance;
	FHazeAudioEventInstance SurfaceAudioEventInstance;

	UNiagaraComponent NiagaraComp;

	float DefaultMoveSpeed = 800.f;
	float Angle = 0.f;

	float OriginalCapsuleHeight;

	bool bGroundPoundedSlidable = false;

	FHazeAcceleratedFloat TurningAcceleratedStrength;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);		
		SlidingComp = UCharacterSlidingComponent::Get(Owner);
		SlidingSettings = USlidingSettings::GetSettings(Owner);
		CrouchComp = UCharacterCrouchComponent::GetOrCreate(Owner);

		HazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::GetOrCreate(Owner);

		DefaultMoveSpeed = MoveComp.MoveSpeed;
		OriginalCapsuleHeight = Player.CapsuleComponent.CapsuleHalfHeight;		

		NiagaraComp = UNiagaraComponent::Create(Owner);
		NiagaraComp.SetAutoActivate(false);
		if (SlidingComp.SlidingEffectTrail != nullptr)
			NiagaraComp.Asset = SlidingComp.SlidingEffectTrail;
		NiagaraComp.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{	
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!HasControl())
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsAirborne())
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.DownHit.Component != nullptr)
			if (!MoveComp.DownHit.Component.HasTag(ComponentTags::Slideable))
				return EHazeNetworkActivation::DontActivate;

		// If you are in a sliding volume, you should enter a slide regardless of input
		if (SlidingComp.SlidingVolumeCount >= 1)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (!IsActioning(ActionNames::MovementSlide) && !SlidingComp.bForcedSlideInput)
        	return EHazeNetworkActivation::DontActivate;

		if (IsActioning(n"GroundPoundedSlope"))
        	return EHazeNetworkActivation::ActivateUsingCrumb;

		// Compare speed to required speed (based off of slope angle)
		if (GetVelocityFlattenedToSlope().Size() >= GetRequiredSpeedForSlide())
        	return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return RemoteLocalControlCrumbDeactivation();

		if (!HasControl())
       		return EHazeNetworkDeactivation::DontDeactivate;

		if (MoveComp.IsAirborne())
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.DownHit.Component == nullptr || !MoveComp.DownHit.Component.HasTag(ComponentTags::Slideable))
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// If you are in a sliding volume, you should not deactivate
		if (SlidingComp.SlidingVolumeCount >= 1)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (!IsActioning(ActionNames::MovementSlide) && !SlidingComp.bForcedSlideInput)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// If slope is steep enough that you would slide anyone, you dont need to deactivate
		if (GetVelocityFlattenedToSlope().Size() >= GetRequiredSpeedForSlide())
        	return EHazeNetworkDeactivation::DontDeactivate;

		// If you are going slow enough
		if (GetVelocityFlattenedToSlope().Size() < DefaultMoveSpeed * 0.5f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(MovementSystemTags::Sprint, this);

		if (ConsumeAction(n"GroundPoundedSlope") == EActionStateStatus::Active)
			bGroundPoundedSlidable = true;

		SlidingComp.bIsSliding = true;
		Player.SetCapabilityActionState(SlidingActivationEvents::NormalSliding, EHazeActionState::Active);

		SlidingComp.BlendSpaceValues = FVector2D::ZeroVector;
		TurningAcceleratedStrength.SnapTo(0.f, 0.f);
		UPhysicalMaterialAudio AudioMat = PostAudioEvents(true);
		if (AudioMat != nullptr && AudioMat.SlidingTrailEffect != nullptr)
			NiagaraComp.Asset = AudioMat.SlidingTrailEffect;
		else
			NiagaraComp.Asset = SlidingComp.SlidingEffectTrail;

		NiagaraComp.Activate();

		UMovementSettings::SetWalkableSlopeAngle(Owner, 89.f, this);
		Player.CapsuleComponent.HazeSetCapsuleHalfHeight(SlidingSettings.CrouchHeight * 0.5f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(MovementSystemTags::Sprint, this);

		Player.SetCapabilityActionState(SlidingActivationEvents::NormalSliding, EHazeActionState::Inactive);

		Player.CapsuleComponent.HazeSetCapsuleHalfHeight(OriginalCapsuleHeight);
		UMovementSettings::ClearWalkableSlopeAngle(Player, this);
		SlidingComp.bIsSliding = false;
		SlidingComp.DesiredMeshRotation = FRotator::ZeroRotator;
		SlidingComp.SlopeNormal = FVector::ZeroVector;

		NiagaraComp.Deactivate();

		if (CheckPlayerCapsuleHit(Player, OriginalCapsuleHeight))
			CrouchComp.ForceCrouch();

		PostAudioEvents(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Sliding");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"SlopeSliding");
		
		CrumbComp.LeaveMovementCrumb();	
		UpdateDesiredMeshRotation(FrameMove.Velocity, DeltaTime);

		// Update animation blend space (will interp the blend sapce)
		SlidingComp.BlendSpaceValues = GetBlendSpaceValues(DeltaTime);

		if (IsDebugActive())
			DrawDebug();
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector Velocity = Math::ConstrainVectorToSlope(MoveComp.Velocity, MoveComp.DownHit.Normal, MoveComp.WorldUp);		

			if (bGroundPoundedSlidable)
			{
				FVector SlopeDirection = GetSlopeDirection(MoveComp.DownHit.ImpactNormal, MoveComp.WorldUp);
				FVector ConstrainedForward = Math::ConstrainVectorToSlope(Player.ViewRotation.ForwardVector, MoveComp.DownHit.ImpactNormal, MoveComp.WorldUp).GetSafeNormal();
				FVector SlideEnterDirection = ConstrainedForward;
				//SlideEnterDirection *= FMath::Sign(SlideEnterDirection.DotProduct(SlopeDirection));				
				SlideEnterDirection += SlopeDirection;
				SlideEnterDirection /= 2.f;

				//If the player has the camera into the slope then we go straight down. But if we have it to the side then add a bit of side movement into the slide.
				FVector SlopeHorizontal = SlopeDirection.ConstrainToPlane(MoveComp.WorldUp).SafeNormal;
				if (SlopeHorizontal.DotProduct(Player.ViewRotation.ForwardVector) < -0.8f)
					Velocity = SlopeDirection * FMath::Max(SlidingComp.GroundPoundSlidableVelocity.DotProduct(SlopeDirection), SlidingSettings.GroundPoundMinimumSpeed);
				else
					Velocity = SlideEnterDirection * FMath::Max(SlidingComp.GroundPoundSlidableVelocity.DotProduct(SlopeDirection), SlidingSettings.GroundPoundMinimumSpeed);

				bGroundPoundedSlidable = false;
			}

			SlidingComp.SlopeNormal = MoveComp.DownHit.ImpactNormal;

			// Update velocity speed
			Velocity += GetSlopeAcceleration(Velocity, DeltaTime);
			Velocity -= GetUphillSlopeDeceleration(Velocity, DeltaTime);
			Velocity -=	GetOverIdealDeceleration(Velocity, DeltaTime);

			// Your velocity should still not exceed absolute maximum
			Velocity = Velocity.GetClampedToMaxSize(SlidingSettings.SpeedSettings.MaximumSpeed);

			// Update velocity rotation
			Velocity = GetSlopeRotatedVelocity(Velocity, DeltaTime);
			Velocity = GetInputRotatedVelocity(Velocity, DeltaTime);

			/*
			Add gravity if you are airborne?
			*/

			// Rotate Player
			const float MaxTurnAngle = 30.f;
			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

			FVector TargetFacingDirection = Velocity.GetSafeNormal();
			if (!MoveInput.IsNearlyZero())
				TargetFacingDirection = RotateVectorTowardsAroundAxis(TargetFacingDirection, MoveInput, MoveComp.WorldUp, MaxTurnAngle * MoveInput.Size());

			MoveComp.SetTargetFacingDirection(TargetFacingDirection, 5.f);
			
			FrameMove.OverrideStepDownHeight(80.f);
			FrameMove.ApplyVelocity(Velocity);
			FrameMove.ApplyAndConsumeImpulses();
		
			FrameMove.ApplyTargetRotationDelta();	
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}	
	}

	FVector GetVelocityFlattenedToSlope() const
	{
		FVector ConstrainedVelocity = Math::ConstrainVectorToSlope(MoveComp.Velocity, MoveComp.DownHit.ImpactNormal, MoveComp.WorldUp);
		return ConstrainedVelocity;
	}

	FVector2D GetBlendSpaceValues(float DeltaTime)
	{
		FVector2D BlendSpaceValues;
		float Input = (Angle * RAD_TO_DEG) / SlidingSettings.TurningSettings.InputRotationRate;

		FVector SlopeNormal = MoveComp.DownHit.Normal;
		FVector SlopeDirection = GetSlopeDirection(SlopeNormal.GetSafeNormal(), MoveComp.WorldUp);
		float RotationDirection = FMath::Sign(Player.ActorRightVector.DotProduct(SlopeDirection));
		float SlopeSteepness = SlopeDirection.DotProduct(-MoveComp.WorldUp);
		float SlopeRelativeVelocity = 1 - FMath::Abs(MoveComp.Velocity.GetSafeNormal().DotProduct(SlopeDirection));
		float SlopeRotation = SlopeSteepness * SlopeRelativeVelocity * RotationDirection;

		float TargetX = FMath::Clamp(Input + SlopeRotation, -1.f, 1.f);

		BlendSpaceValues.X = FMath::FInterpTo(SlidingComp.BlendSpaceValues.X, TargetX, DeltaTime, 8.f);
		BlendSpaceValues.Y = GetEffectiveSlopeAngle(MoveComp.DownHit.ImpactNormal, MoveComp.WorldUp, MoveComp.Velocity);
		return BlendSpaceValues;
	}

	/* 
		Get the raw acceleration from the slope angle, relative to your velocity
		Will decelerate you if you are sliding uphill
	*/
	FVector GetSlopeAcceleration(FVector Velocity, float DeltaTime)
	{
		FVector AccelerationDir = GetAccelerationDirection();
		FVector ConstrainedAccelerationDir = Math::ConstrainVectorToSlope(AccelerationDir, MoveComp.DownHit.Normal, MoveComp.WorldUp);
		float SteepnessDot = ConstrainedAccelerationDir.DotProduct(-MoveComp.WorldUp);
		float SteepnessScale = (90.f - (FMath::Acos(SteepnessDot) * RAD_TO_DEG)) / 90.f;

		FVector Acceleration = AccelerationDir * SteepnessScale * SlidingSettings.SpeedSettings.Acceleration;
		return Acceleration * DeltaTime;
	}

	FVector GetUphillSlopeDeceleration(FVector Velocity, float DeltaTime)
	{
		FVector AccelerationDir = GetAccelerationDirection();
		FVector ConstrainedAccelerationDir = Math::ConstrainVectorToSlope(AccelerationDir, MoveComp.DownHit.Normal, MoveComp.WorldUp);
		float SteepnessDot = ConstrainedAccelerationDir.DotProduct(MoveComp.WorldUp);

		float SteepnessAngle = 90 - Math::DotToDegrees(SteepnessDot);
		const float DownhillStartAngle = -15.f;
		const float NeutralSteepnessScale = 0.5f;
		const float UphillEndAngle = 30.f;

		float SteepnessScale = 0.f;
		if (SteepnessAngle <= 0.f)
			SteepnessScale = Math::GetMappedRangeValueClamped(DownhillStartAngle, 0.f, 0.f, NeutralSteepnessScale, SteepnessAngle);
		else
			SteepnessScale = Math::GetMappedRangeValueClamped(0.f, UphillEndAngle, NeutralSteepnessScale, 1.f, SteepnessAngle);

		PrintToScreenScaled("SteepnessScale: " + SteepnessScale, Scale = 2.f);

		FVector Acceleration = AccelerationDir * SteepnessScale * SlidingSettings.SpeedSettings.Decceleration;
		return Acceleration * DeltaTime;
	}

	// If you go over ideal maximum speed, you should drag down to ideal speed
	FVector GetOverIdealDeceleration(FVector Velocity, float DeltaTime)
	{
		if (Velocity.Size() <= SlidingSettings.SpeedSettings.SoftMaximumSpeed)
			return FVector::ZeroVector;
		
		FVector Drag = Velocity * SlidingSettings.SpeedSettings.PostIdealMaximumSpeedDrag * DeltaTime;
		float DeltaToSoftMaximum = Velocity.Size() - SlidingSettings.SpeedSettings.SoftMaximumSpeed;
		
		if (Drag.Size() >= DeltaToSoftMaximum)
			Drag = Drag.GetSafeNormal() * DeltaToSoftMaximum;
		
		return Drag;
	}

	FVector GetSlopeRotatedVelocity(FVector Velocity, float DeltaTime)
	{
		FVector SlopeNormal = MoveComp.DownHit.Normal;
		FVector SlopeDirection = GetSlopeDirection(SlopeNormal.GetSafeNormal(), MoveComp.WorldUp);

		float SlopeSteepness = SlopeDirection.DotProduct(-MoveComp.WorldUp);
		float SlopeRelativeVelocity = 1 - FMath::Abs(Velocity.GetSafeNormal().DotProduct(SlopeDirection));

		float Alpha = SlidingSettings.TurningSettings.SlopeRotationRate * SlopeSteepness * SlopeRelativeVelocity * DeltaTime;
		
		FVector NewVel = Math::RotateVectorTowards(Velocity, SlopeDirection, Alpha);
		return NewVel;
	}

	FVector GetInputRotatedVelocity(FVector Velocity, float DeltaTime)
	{
		FVector SlopeNormal = MoveComp.DownHit.Normal;

		// Rotate like standard character
		{
			float TurnScale = GetAttributeVector(AttributeVectorNames::LeftStickRaw).Size();
			float TurnRate = SlidingSettings.TurningSettings.InputRotationRate * DEG_TO_RAD;

			// If my angle different is lower than the angle turn, that is my target angle

			// Calculate Current and Target direction
			FVector CurrentDirection = Velocity.GetSafeNormal();
			FVector TargetDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			TargetDirection = Math::ConstrainVectorToSlope(TargetDirection, SlopeNormal, MoveComp.WorldUp).GetSafeNormal();

			float AngleDifference = FMath::Acos(CurrentDirection.DotProduct(TargetDirection));

			// Calculate the Axis and the angle of rotation
			FVector Axis = MoveComp.DownHit.ImpactNormal;
			FVector AxisRight = Axis.CrossProduct(CurrentDirection);
			float RotationDirection = FMath::Sign(AxisRight.DotProduct(TargetDirection));
			
			Angle = TurnRate * TurnScale;
			if (AngleDifference < Angle)
				Angle = AngleDifference;
			Angle *= RotationDirection;

			TurningAcceleratedStrength.AccelerateTo(Angle, 0.8f, DeltaTime);
			
			float AngleRemaining = FMath::Acos(CurrentDirection.DotProduct(TargetDirection));
			FQuat RotationQuat = FQuat(Axis, TurningAcceleratedStrength.Value * DeltaTime);

			FVector NewDirection = RotationQuat * (CurrentDirection * Velocity.Size());
			return NewDirection;						
		}
	}

	float GetSlopeVelocityDot(FVector Velocity) const
	{
		FVector SlopeNormal = MoveComp.DownHit.Normal;
		FVector SlopeDirection = GetSlopeDirection(SlopeNormal.GetSafeNormal(), MoveComp.WorldUp);
		
		return SlopeDirection.DotProduct(Velocity.GetSafeNormal());
	}

	FVector GetAccelerationDirection() const
	{
		if (MoveComp.Velocity.IsNearlyZero())
			return GetSlopeDirection(MoveComp.DownHit.Normal, MoveComp.WorldUp);
		else
			return MoveComp.Velocity.GetSafeNormal();
	}

	float GetRequiredSpeedForSlide() const
	{	
		float RequiredSpeed = 0.f;
		float EffectiveAngle = GetEffectiveSlopeAngle(MoveComp.DownHit.Normal, MoveComp.WorldUp, MoveComp.Velocity.GetSafeNormal());

		if (SlidingComp.SlideSpeedCurve != nullptr)
			RequiredSpeed = DefaultMoveSpeed * SlidingComp.SlideSpeedCurve.GetFloatValue(EffectiveAngle);
		else
			RequiredSpeed = DefaultMoveSpeed * 1.4f;
		
		return RequiredSpeed;
	}

	void UpdateDesiredMeshRotation(FVector Velocity, float DeltaTime)
	{	
		FVector RotationX = Velocity;

		SlidingComp.DesiredMeshRotation = Math::MakeRotFromXZ(RotationX, MoveComp.DownHit.Normal);	
	}

	UPhysicalMaterialAudio PostAudioEvents(bool bActivated) 
	{
		if (bActivated) 
		{
			ReaffirmAudioEventsAreStopped();

			UPhysicalMaterialAudio AudioPhysMat =  PhysicalMaterialAudio::GetPhysicalMaterialAudioAsset(MoveComp.DownHit.Component);		

			if(AudioPhysMat == nullptr)
				AudioPhysMat = AudioMoveComp.DefaultPhysAudioAsset;		

			UAkAudioEvent MaterialEvent = Player.IsMay() ? AudioPhysMat.MayMaterialEvents.MayMaterialAssSlideEvent : AudioPhysMat.CodyMaterialEvents.CodyMaterialAssSlideEvent;
			if(MaterialEvent != nullptr)
			{
				MaterialAudioEventInstance = HazeAkComp.HazePostEvent(MaterialEvent);
			}
			
			UAkAudioEvent SurfaceEvent = AudioMoveComp.GetDefaultFootstepEvent(HazeAudio::EPlayerFootstepType::AssSlideLoop, AudioPhysMat.MaterialType, AudioPhysMat.SlideType);
			if(SurfaceEvent != nullptr)
			{
				SurfaceAudioEventInstance = HazeAkComp.HazePostEvent(SurfaceEvent);
			}	

			return AudioPhysMat;
		}
		else 
		{
			UAkAudioEvent AudioEvent = SlidingComp.AssSlideStopEvent;

			if(AudioEvent != nullptr)
			{
				HazeAkComp.HazePostEvent(AudioEvent);
			}
		}

		return nullptr;
	}

	void ReaffirmAudioEventsAreStopped() 
	{
		if(MaterialAudioEventInstance.PlayingID != 0)
		{
			HazeAkComp.HazeStopEvent(MaterialAudioEventInstance.PlayingID);
			MaterialAudioEventInstance = Audio::GetEmptyEventInstance();
		}

		if(SurfaceAudioEventInstance.PlayingID != 0)
		{
			HazeAkComp.HazeStopEvent(SurfaceAudioEventInstance.PlayingID);
			SurfaceAudioEventInstance = Audio::GetEmptyEventInstance();
		}
	}

	void DrawDebug()
	{
		FVector WorldUp = MoveComp.WorldUp.GetSafeNormal();
		FVector Normal = MoveComp.DownHit.Normal.GetSafeNormal();
		FVector BiNormal = WorldUp.CrossProduct(Normal).GetSafeNormal();
		FVector SlopeDirection = BiNormal.CrossProduct(Normal);

		DebugDrawLineDelta(SlopeDirection * 250.f, FLinearColor::Red);
		DebugDrawLineDelta(BiNormal * 250.f, FLinearColor::Green);
		DebugDrawLineDelta(Normal * 250.f, FLinearColor::Blue);
		DebugDrawArrowDelta(MoveComp.Velocity, 50.f, FLinearColor(1.f, 0.5f, 0.5f), 0.f, 5.f);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";

		DebugText += "<Blue> Current Speed: </>" + String::Conv_FloatToStringOneDecimal(MoveComp.Velocity.Size()) + "\n";
		DebugText += "<Yellow> Soft Maximum Speed: </>" + String::Conv_FloatToStringOneDecimal(SlidingSettings.SpeedSettings.SoftMaximumSpeed) + "\n";
		DebugText += "<Red> Maximum Speed: </>" + String::Conv_FloatToStringOneDecimal(SlidingSettings.SpeedSettings.MaximumSpeed) + "\n";

		return DebugText;
	}
}


UFUNCTION()
void ForceSlideInput(AHazePlayerCharacter Player, bool bValue)
{
	if (Player == nullptr)
		return;
	UCharacterSlidingComponent SlidingComp = UCharacterSlidingComponent::Get(Player);

	if (SlidingComp == nullptr)
		return;

	SlidingComp.bForcedSlideInput = bValue;
}
