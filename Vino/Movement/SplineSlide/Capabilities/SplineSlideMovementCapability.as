import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideSettings;
import Rice.Math.MathStatics;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.SplineSlide.SplineSlideTags;
import Vino.Movement.SplineSlide.SplineSlideSpline;

class USplineSlideMovementCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(SplineSlideTags::GroundMovement);
	default CapabilityTags.Add(SplineSlideTags::Movement);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;
	UCharacterSlidingComponent IncorrectSlidingComp;

	UHazeAkComponent HazeAkComp;
	UPlayerMovementAudioComponent AudioMoveComp;
	FHazeAudioEventInstance MaterialAudioEventInstance;
	FHazeAudioEventInstance SurfaceAudioEventInstance;

	UPhysicalMaterialAudio OverridenAudioPhysmat;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);	
		IncorrectSlidingComp = UCharacterSlidingComponent::GetOrCreate(Owner);
		HazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsAirborne())
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PostAudioEvents(true);

		if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
			SplineSlideComp.ActiveSplineSlideSpline.OnSlideLanded.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PostAudioEvents(false);

		IncorrectSlidingComp.SlopeNormal = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SplineSlide");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"SlopeSliding");

		CrumbComp.LeaveMovementCrumb();
		
		MoveComp.Velocity = MoveComp.RequestVelocity;

		if(ConsumeAction(n"AudioSlidingMaterialOverrideClear") == EActionStateStatus::Active)
			OverridenAudioPhysmat = nullptr;	
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			const float DistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
			const FVector SplineNearestLocation = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			const FVector SplineForward = SplineSlideComp.ActiveSplineSlideSpline.GetSplineForward(DistanceAlongSpline);
			const FVector SplineRight = SplineSlideComp.ActiveSplineSlideSpline.GetSplineRight(DistanceAlongSpline);
			const FVector SplineUp = SplineSlideComp.ActiveSplineSlideSpline.GetSplineUp(DistanceAlongSpline);

			IncorrectSlidingComp.SlopeNormal = SplineUp;
			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

			// Calculate an acceleration direction based off of the splines forward and roll angle
			FVector WorldUpRight = MoveComp.WorldUp.CrossProduct(SplineForward).GetSafeNormal();
			float SplineRollAngle = WorldUpRight.AngularDistance(SplineRight) * SplineSlideComp.SplineSettings.Longitudinal.SplineForwardRollAdjustedScale * FMath::Sign(-MoveComp.WorldUp.DotProduct(SplineRight));
			FQuat SplineForwardRotationQuat(SplineUp, SplineRollAngle);
			FVector AccelerationSplineForward = SplineForwardRotationQuat * SplineForward;	

			// Split the velocity into longitudinal and lateral
			FVector Velocity = Math::ConstrainVectorToSlope(MoveComp.Velocity, MoveComp.DownHit.Normal, MoveComp.WorldUp);
			FVector LongitudinalVelocity = Velocity.ConstrainToDirection(AccelerationSplineForward);
			FVector LateralVelocity = Velocity - LongitudinalVelocity;

			if (IsDebugActive())
			{
				DebugDrawLineDelta(LongitudinalVelocity, FLinearColor::Red, 0.f, 5.f);
				DebugDrawLineDelta(LateralVelocity, FLinearColor::Green, 0.f, 5.f);
			}

			// Longitudinal acceleration / deceleration
			// LongitudinalVelocity -= LongitudinalVelocity * SplineSlideComp.SplineSettings.Longitudinal.DragCoefficient * DeltaTime * (1 - (SplineSlideComp.RubberbandScale - 1.f));
			// LongitudinalVelocity += AccelerationSplineForward * SplineSlideComp.SplineSettings.Longitudinal.Acceleration * DeltaTime * SplineSlideComp.RubberbandScale;
			// // Clamp Longitudinal speed 
			// float LongitudinalSpeed = LongitudinalVelocity.DotProduct(AccelerationSplineForward);
			// LongitudinalSpeed = FMath::Min(LongitudinalSpeed, SplineSlideComp.SplineSettings.Longitudinal.MaximumSpeed * SplineSlideComp.RubberbandScale);
			LongitudinalVelocity = AccelerationSplineForward * SplineSlideComp.CurrentLongitudinalSpeed;

			// Lateral acceleration / deceleration
			LateralVelocity -= LateralVelocity * SplineSlideComp.SplineSettings.Lateral.DragCoefficient * DeltaTime;
			LateralVelocity += MoveInput.ConstrainToDirection(SplineRight) * SplineSlideComp.SplineSettings.Lateral.Acceleration * DeltaTime;
			LateralVelocity = LateralVelocity.GetClampedToMaxSize(SplineSlideComp.SplineSettings.Lateral.MaximumSpeed);

			// Merge them together and constrain them to spline
			Velocity = LongitudinalVelocity + LateralVelocity;
			FVector DeltaMove = Velocity * DeltaTime;
			
			if (SplineSlideComp.ActiveSplineSlideSpline.bLockToSplineWidth)
				SplineSlideComp.ConstrainVelocityToSpline(Velocity, DeltaMove, DeltaTime);

			FrameMove.FlagToMoveWithDownImpact();
			FrameMove.ApplyDeltaWithCustomVelocity(DeltaMove, Velocity);

			// If you are inside a ramp jump, don't do a step down
			if (SplineSlideComp.ActiveRampJumps.Num() > 0)
				FrameMove.OverrideStepDownHeight(0.f);

			// Calculate facing direction and rotate the character
			FVector TargetFacingDirection = SplineForward;
			TargetFacingDirection = AccelerationSplineForward;

			if (!MoveInput.ConstrainToDirection(SplineRight).IsNearlyZero())
			{
				if (SplineSlideComp.SplineSettings.Lateral.DragCoefficient != 0.f)
				{
					float DesiredLateralSpeed = SplineSlideComp.SplineSettings.Lateral.Acceleration / SplineSlideComp.SplineSettings.Lateral.DragCoefficient;
					TargetFacingDirection = (LongitudinalVelocity + (MoveInput.ConstrainToDirection(SplineRight) * DesiredLateralSpeed)).GetSafeNormal();
				}
				if (IsDebugActive())
					DebugDrawLineDelta(Owner.ActorLocation + DeltaMove, TargetFacingDirection * 500.f, FLinearColor::Purple, 0.f, 5.f);
			}
			MoveComp.SetTargetFacingDirection(TargetFacingDirection, 5.f);

			// Calulate the blend space value
			FVector DirectionVector = SplineUp.CrossProduct(Velocity);
			float AngleDifference = Velocity.AngularDistance(TargetFacingDirection) * RAD_TO_DEG;
			float BlendspaceTarget = 0.f;
			float MaxAngleDifference = SplineForward.AngularDistance(LongitudinalVelocity + (SplineRight * SplineSlideComp.SplineSettings.Lateral.Acceleration / SplineSlideComp.SplineSettings.Lateral.DragCoefficient));
			if (MaxAngleDifference != 0.f)
			{
				BlendspaceTarget = AngleDifference / (MaxAngleDifference * RAD_TO_DEG) * FMath::Sign(TargetFacingDirection.DotProduct(DirectionVector));
				BlendspaceTarget = FMath::Clamp(BlendspaceTarget, -1.f, 1.f);
			}

			IncorrectSlidingComp.BlendSpaceValues.X = FMath::FInterpTo(IncorrectSlidingComp.BlendSpaceValues.X, BlendspaceTarget, DeltaTime, 8.f);

			if (IsDebugActive())
			{
				DebugDrawLineDelta(Owner.ActorLocation + DeltaMove, SplineForward * 400.f, FLinearColor::Red);
				DebugDrawLineDelta(Owner.ActorLocation + DeltaMove, AccelerationSplineForward * 400.f, FLinearColor(0.6f, 0.4f, 0.4f));

				DebugDrawLineDelta(Owner.ActorLocation + DeltaMove, SplineRight * 400.f, FLinearColor::Green);
				DebugDrawLineDelta(Owner.ActorLocation + DeltaMove, WorldUpRight * 400.f, FLinearColor(0.4f, 0.6f, 0.4f));
				DebugDrawLineDelta(Owner.ActorLocation + DeltaMove, SplineUp * 400.f, FLinearColor::Blue);
				DebugDrawLineDelta(Owner.ActorLocation + DeltaMove, MoveComp.WorldUp * 400.f, FLinearColor(0.3f, 0.4f, 0.6f));

				PrintToScreenScaled("SplineRollAngle: " + SplineRollAngle);
				//PrintToScreenScaled("AngleDifference: " + AngleDifference);				
			}		
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}

	void PostAudioEvents(bool bActivated) 
	{
		if (bActivated) 
		{
			ReaffirmAudioEventsAreStopped();
			UPhysicalMaterialAudio AudioPhysMat;

			UObject RawAsset;
			if(ConsumeAttribute(n"AudioSlidingMaterialOverride", RawAsset))
			{
				AudioPhysMat = Cast<UPhysicalMaterialAudio>(RawAsset);
				OverridenAudioPhysmat = AudioPhysMat;
			}
			else
				AudioPhysMat = OverridenAudioPhysmat == nullptr ? PhysicalMaterialAudio::GetPhysicalMaterialAudioAsset(MoveComp.DownHit.Component) : OverridenAudioPhysmat;

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
		}
		else 
		{
			UAkAudioEvent AudioEvent = IncorrectSlidingComp.AssSlideStopEvent;

			if(AudioEvent != nullptr)
			{
				HazeAkComp.HazePostEvent(AudioEvent);
			}
		}
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

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";
		if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
		{
			const float DistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
			//const FVector SplineNearestLocation = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			const FVector SplineForward = SplineSlideComp.ActiveSplineSlideSpline.GetSplineForward(DistanceAlongSpline);
			//const FVector SplineRight = SplineSlideComp.ActiveSplineSlideSpline.GetSplineRight(DistanceAlongSpline);
			//const FVector SplineUp = SplineSlideComp.ActiveSplineSlideSpline.GetSplineUp(DistanceAlongSpline);

			FVector Velocity = MoveComp.Velocity;
			float LongitudinalSpeed = Velocity.DotProduct(SplineForward);
			float LateralSpeed = Velocity.Size() - LongitudinalSpeed;

			DebugText += "<Red> Longitudinal Speed: </>" + String::Conv_FloatToStringOneDecimal(LongitudinalSpeed) + "\n";
			DebugText += "<Green> Lateral Speed: </>" + String::Conv_FloatToStringOneDecimal(LateralSpeed) + "\n";
			DebugText += "<White> Rubberband Scale: </>" + String::Conv_FloatToStringThreeDecimal(SplineSlideComp.RubberbandScale) + "\n" + "\n";
			//DebugText += "<Red> Mathematical Longitudinal Max Speed: </>" + String::Conv_FloatToStringOneDecimal(SplineSlideComp.SplineSettings.Longitudinal.Acceleration / SplineSlideComp.SplineSettings.Longitudinal.DragCoefficient) + "\n";
			DebugText += "<Green> Mathematical Lateral Max Speed: </>" + String::Conv_FloatToStringOneDecimal(SplineSlideComp.SplineSettings.Lateral.Acceleration / SplineSlideComp.SplineSettings.Lateral.DragCoefficient) + "\n";

		}

		//DebugText += "<Yellow> Soft Maximum Speed: </>" + String::Conv_FloatToStringOneDecimal(SplineSlideSettings::Speed.SoftMaximumSpeed) + "\n";
		//DebugText += "<Red> Maximum Speed: </>" + String::Conv_FloatToStringOneDecimal(SplineSlideSettings::Speed.MaximumSpeed) + "\n";

		return DebugText;
	}

	// /* 
	// 	Get the raw acceleration from the slope angle, relative to your velocity, and clamp it to the spline
	// 	Will decelerate you if you are sliding uphill
	// */
	// FVector GetSlopeAcceleration(FVector Velocity, float DeltaTime)
	// {
	// 	FVector AccelerationDir = GetAccelerationDirection();
	// 	FVector ConstrainedAccelerationDir = Math::ConstrainVectorToSlope(AccelerationDir, MoveComp.DownHit.Normal, MoveComp.WorldUp);
	// 	float SteepnessDot = ConstrainedAccelerationDir.DotProduct(-MoveComp.WorldUp);
	// 	float SteepnessScale = (90.f - (FMath::Acos(SteepnessDot) * RAD_TO_DEG)) / 90.f;

	// 	FVector Acceleration = AccelerationDir * SteepnessScale * SplineSlideSettings::Speed.LongitudinalAcceleration;
	// 	return Acceleration * DeltaTime;
	// }

	// // If you go over ideal maximum speed, you should drag down to ideal speed
	// FVector GetOverSoftMaximumDeceleration(FVector Velocity, float DeltaTime)
	// {
	// 	if (Velocity.Size() <= SplineSlideSettings::Speed.SoftMaximumSpeed)
	// 		return FVector::ZeroVector;
		
	// 	FVector Drag = Velocity * SplineSlideSettings::Speed.PostSoftMaximumDrag * DeltaTime;
	// 	float DeltaToSoftMaximum = Velocity.Size() - SplineSlideSettings::Speed.SoftMaximumSpeed;
		
	// 	if (Drag.Size() >= DeltaToSoftMaximum)
	// 		Drag = Drag.GetSafeNormal() * DeltaToSoftMaximum;
		
	// 	return Drag;
	// }

	// FVector GetSlopeRotatedVelocity(FVector Velocity, float DeltaTime)
	// {
	// 	FVector SlopeNormal = MoveComp.DownHit.Normal;
	// 	FVector SlopeDirection = GetSlopeDirection(SlopeNormal.GetSafeNormal(), MoveComp.WorldUp);

	// 	float SlopeSteepness = SlopeDirection.DotProduct(-MoveComp.WorldUp);
	// 	float SlopeRelativeVelocity = 1 - FMath::Abs(Velocity.GetSafeNormal().DotProduct(SlopeDirection));

	// 	float Alpha = SplineSlideSettings::Turning.SlopeRotationRate * SlopeSteepness * SlopeRelativeVelocity * DeltaTime;
		
	// 	FVector NewVel = Math::RotateVectorTowards(Velocity, SlopeDirection, Alpha);
	// 	return NewVel;
	// }

	// // Will rotate velocity towards the tangents direction
	// FVector GetTangentRotatedVelocity(FVector Velocity, FVector Tangent, float DeltaTime)
	// {	
	// 	return Math::RotateVectorTowardsAroundAxis(Velocity, Tangent, MoveComp.DownHit.Normal, SplineSlideSettings::Turning.TangentRotationRate * DeltaTime);
	// }	

	// FVector GetInputRotatedVelocity(FVector Velocity, float DeltaTime)
	// {
	// 	FVector SlopeNormal = MoveComp.DownHit.Normal;

	// 	// Rotate like standard character
	// 	{
	// 		float TurnScale = GetAttributeVector(AttributeVectorNames::LeftStickRaw).Size();
	// 		float TurnRate = SplineSlideSettings::Turning.InputRotationRate * DEG_TO_RAD;

	// 		// If my angle different is lower than the angle turn, that is my target angle

	// 		// Calculate Current and Target direction
	// 		FVector CurrentDirection = Velocity.GetSafeNormal();
	// 		FVector TargetDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
	// 		TargetDirection = Math::ConstrainVectorToSlope(TargetDirection, SlopeNormal, MoveComp.WorldUp).GetSafeNormal();

	// 		float AngleDifference = FMath::Acos(CurrentDirection.DotProduct(TargetDirection));

	// 		// Calculate the Axis and the angle of rotation
	// 		FVector Axis = MoveComp.DownHit.ImpactNormal;
	// 		FVector AxisRight = Axis.CrossProduct(CurrentDirection);
	// 		float RotationDirection = FMath::Sign(AxisRight.DotProduct(TargetDirection));
			
	// 		float Angle = TurnRate * TurnScale;
	// 		if (AngleDifference < Angle)
	// 			Angle = AngleDifference;
	// 		Angle *= RotationDirection;

	// 		TurningAcceleratedStrength.AccelerateTo(Angle, 0.8f, DeltaTime);
			
	// 		float AngleRemaining = FMath::Acos(CurrentDirection.DotProduct(TargetDirection));
	// 		FQuat RotationQuat = FQuat(Axis, TurningAcceleratedStrength.Value * DeltaTime);

	// 		FVector NewDirection = RotationQuat * (CurrentDirection * Velocity.Size());
	// 		return NewDirection;						
	// 	}
	// }	

	// FVector GetAccelerationDirection() const
	// {
	// 	if (MoveComp.Velocity.IsNearlyZero())
	// 		return GetSlopeDirection(MoveComp.DownHit.Normal, MoveComp.WorldUp);
	// 	else
	// 		return MoveComp.Velocity.GetSafeNormal();
	// }

	// // Returns a normalized vector in the direction down the slope
	// FVector GetSlopeDirection(FVector Normal, FVector WorldUp) const
	// {
	// 	FVector BiNormal = Normal.CrossProduct(WorldUp);
	// 	return Normal.CrossProduct(BiNormal).GetSafeNormal();
	// }

	
}
