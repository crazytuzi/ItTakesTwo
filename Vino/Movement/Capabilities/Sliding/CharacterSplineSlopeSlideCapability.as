import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Sliding.SlidingNames;
import Peanuts.Spline.SplineComponent;
import Vino.Movement.Capabilities.Sliding.SplineSlopeSlidingSettings;
import Vino.Movement.Capabilities.Sliding.CharacterSplineSlopeSlidingComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

// class USlopeSlideCustomVelocityCalculator : UHazeVelocityCalculator
// {
// 	UFUNCTION(BlueprintOverride)
// 	FVector CalculateVelocity(const UCollisionCheckActorData ActorData, FMovementCollisionData ImpactData, FVector DeltaMoved, const float DeltaTime) const
// 	{
// 		// FVector DeltaMovedVelocity = (DeltaMoved / DeltaTime) / ActorData.ActorScale;
// 		// FVector RequestedVelocity = ActorData.RequestVelocity;

// 		// const FVector HorizontalVelocity = DeltaMovedVelocity.ConstrainToPlane(ActorData.WorldUp);
// 		// const FVector VerticalVelocity = RequestedVelocity.ConstrainToDirection(ActorData.WorldUp);



// 		// //return HorizontalVelocity + VerticalVelocity;
// 		return ActorData.RequestVelocity;
// 	}	
// }

class UCharacterSplineSlopeSlideCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::SlopeSlide);
    default CapabilityTags.Add(SlidingTags::Horizontal);
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 135;

	default CapabilityDebugCategory = CapabilityTags::Movement;
	
	// Internal Variables
	AHazePlayerCharacter Player;	

	UCharacterSlopeSlideComponent SlideComp;

	UPROPERTY()
	FSplineSlopeSlidingSettings SlidingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(CharacterOwner);

		SlideComp = UCharacterSlopeSlideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
        
		if (SlideComp.GuideSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;
			
		if (MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (SlideComp.GuideSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);

		FVector SplineDirection = FVector::ZeroVector;
		FVector SplineRightVector = FVector::ZeroVector;
		SlideComp.GetCurrentDirectionAlongSpline(MoveComp, SplineDirection, SplineRightVector, true);

		USplineSlopeSlidingTurnSettings TurnSettings = USplineSlopeSlidingTurnSettings::GetSettings(Owner);
		SlideComp.SplineSideAccelerator.Value = FMath::Clamp(SlideComp.SplineSideAccelerator.Value, -TurnSettings.MaxSideSpeed, TurnSettings.MaxSideSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);

		FRotator Rotation = Math::ConstructRotatorFromUpAndForwardVector(MoveComp.OwnerRotation.ForwardVector, MoveComp.WorldUp);
		Player.RootOffsetComponent.OffsetRotationWithSpeed(Rotation, -1.f);
	}

	FVector CalculateVelocityInSplineDirection(FVector SplineDirection, FVector InputVector, float DeltaTime)
	{
		float ForwardSpeed = SlideComp.CalculateSpeedInSplineDirection(MoveComp, SplineDirection, InputVector, DeltaTime);
		
		// Keep may behind cody.
		ForwardSpeed = RubberBandMay(ForwardSpeed);

		return SplineDirection * ForwardSpeed;
	}

	float RubberBandMay(float NormalWantedSpeed)
	{
		if (!Player.IsMay())
			return NormalWantedSpeed;

		if (IsPlayerDead(Player) || IsPlayerDead(Player.OtherPlayer))
			return NormalWantedSpeed;

		float OutputSpeed = NormalWantedSpeed;

		FVector CodyLocation = Player.OtherPlayer.GetActorLocation();
		const float CodyDistanceOnSpline = SlideComp.GuideSpline.GetDistanceAlongSplineAtWorldLocation(CodyLocation);
		
		const float Dif = CodyDistanceOnSpline - SlideComp.CurrentDistanceAlongSpline;

		if (IsDebugActive())
			DebugDrawRubberBandArea();

		if (Dif < SlidingSettings.MayStartClampingSpeedDistance)
		{
			float BreakSpeed = SlidingSettings.RubberBandBreakSpeed;
			if (Dif > SlidingSettings.MayMaxForwardDistanceToCody)
			{
				const float MaxValue = SlidingSettings.MayStartClampingSpeedDistance - SlidingSettings.MayMaxForwardDistanceToCody;
				const float RelativeDifValue = Dif - SlidingSettings.MayMaxForwardDistanceToCody;

				BreakSpeed = FMath::Lerp(BreakSpeed, 0.f, RelativeDifValue / MaxValue);
			}

			// May is to close to Cody
			OutputSpeed -= BreakSpeed;
		}
		else if (Dif > SlidingSettings.MayStartCatchingUpDistance)
		{
			float SpeedBoost = SlidingSettings.RubberBandSpeedBoost;
			if (Dif < SlidingSettings.MayMaxBehindDistanceToCody)
			{
				const float MaxValue = SlidingSettings.MayMaxBehindDistanceToCody - SlidingSettings.MayStartCatchingUpDistance;
				const float RelativeDifValue = Dif - SlidingSettings.MayStartCatchingUpDistance;

				SpeedBoost = FMath::Lerp(0.f, SpeedBoost, RelativeDifValue / MaxValue);
			}

			// May is to far behind Cody
			OutputSpeed += SpeedBoost;
		}

		return OutputSpeed;
	}

	void DebugDrawRubberBandArea()
	{
		FVector CodyLocation = Player.OtherPlayer.GetActorLocation();
		const float CodyDistanceOnSpline = SlideComp.GuideSpline.GetDistanceAlongSplineAtWorldLocation(CodyLocation);
		FVector CodyDirection = SlideComp.GuideSpline.GetTangentAtDistanceAlongSpline(CodyDistanceOnSpline, ESplineCoordinateSpace::World);

		float StartClampingSpeedDistance = SlidingSettings.MayStartClampingSpeedDistance - SlidingSettings.MayMaxForwardDistanceToCody;
		float RubberBandDistance = SlidingSettings.MayMaxBehindDistanceToCody - SlidingSettings.MayMaxForwardDistanceToCody;
		float StartRubberBandingDistance = SlidingSettings.MayMaxBehindDistanceToCody - SlidingSettings.MayStartCatchingUpDistance;
		
		FVector CurrentLocationOnSpline = SlideComp.GuideSpline.GetLocationAtDistanceAlongSpline(SlideComp.CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);

		FVector ClampSpeedLocationLocation = SlideComp.GuideSpline.GetLocationAtDistanceAlongSpline(CodyDistanceOnSpline - SlidingSettings.MayMaxForwardDistanceToCody - StartClampingSpeedDistance / 2.f, ESplineCoordinateSpace::World);
		FVector RubberBandBoxLocation = SlideComp.GuideSpline.GetLocationAtDistanceAlongSpline(CodyDistanceOnSpline - SlidingSettings.MayMaxForwardDistanceToCody - RubberBandDistance / 2.f, ESplineCoordinateSpace::World);
		FVector StartRubberBandLocation = SlideComp.GuideSpline.GetLocationAtDistanceAlongSpline(CodyDistanceOnSpline - SlidingSettings.MayStartCatchingUpDistance - StartRubberBandingDistance / 2.f, ESplineCoordinateSpace::World);

		FRotator BoxRotation = Math::ConstructRotatorFromUpAndForwardVector(CodyDirection, Player.OtherPlayer.ActorRotation.UpVector);
		System::DrawDebugSphere(RubberBandBoxLocation, 65.f, 12, FLinearColor::Blue);
		System::DrawDebugSphere(CurrentLocationOnSpline, 65.f, 12, FLinearColor::Green);
		System::DrawDebugBox(RubberBandBoxLocation, FVector(RubberBandDistance / 2.f, 2000.f, 1500.f), FLinearColor::Blue, BoxRotation);
		System::DrawDebugBox(ClampSpeedLocationLocation, FVector(StartClampingSpeedDistance / 2.f, 2000.f, 1500.f), FLinearColor::Red, BoxRotation);
		System::DrawDebugBox(StartRubberBandLocation, FVector(StartRubberBandingDistance / 2.f, 2000.f, 1500.f), FLinearColor::LucBlue, BoxRotation);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement SlideMovement = MoveComp.MakeFrameMovement(SlidingTags::Horizontal);

		FVector SplineDirection = FVector::ZeroVector;
		FVector SplineRightVector = FVector::ZeroVector;
		SlideComp.GetCurrentDirectionAlongSpline(MoveComp, SplineDirection, SplineRightVector, true);

		if (HasControl())
		{
			const FVector InputVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
			const FVector SplineDirectionVelocity = CalculateVelocityInSplineDirection(SplineDirection.GetSafeNormal(), InputVector, DeltaTime);
			const FVector SideVelocity = SlideComp.CalculateSideVelocity(MoveComp, SplineRightVector, InputVector, DeltaTime, IsDebugActive());

			const FVector TotalVelocity = SplineDirectionVelocity + SideVelocity;
			UpdateFacingRotation(TotalVelocity, SplineRightVector, InputVector);
			UpdateBlendSpaceValue(SideVelocity, SplineDirectionVelocity);

			SlideMovement.ApplyVelocity(TotalVelocity);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			SlideMovement.ApplyConsumedCrumbData(ConsumedParams);
			const FVector TotalVelocity = ConsumedParams.Velocity;

			const FVector SplineDirectionVelocity = TotalVelocity.ConstrainToDirection(SplineDirection);
			const FVector SideVelocity = TotalVelocity.ConstrainToDirection(SplineRightVector);

			UpdateBlendSpaceValue(SideVelocity, SplineDirectionVelocity);
		}
		
		SlideMovement.ApplyTargetRotationDelta();
        MoveCharacter(SlideMovement, FeatureName::SlopeSliding);
		CrumbComp.LeaveMovementCrumb();

		// Debug Draw Velocities
		{
			// SlopeDebugArrow(StartVelocity, FLinearColor::Blue, MoveComp.WorldUp * 350.f);
			// SlopeDebugArrow(SplineDirection * 1000.f, FLinearColor::Red, MoveComp.WorldUp * 250.f);
			 //SlopeDebugArrow(SplineRightVector * 1000.f, FLinearColor::Yellow, MoveComp.WorldUp * 250.f);
			// SlopeDebugArrow(FrameMovement.Velocity, FLinearColor::Green, MoveComp.WorldUp * 150.f);

			// CodyPrint(Owner, "SplineDirection: " + SplineDirectionVelocity.Size());
			// CodyPrint(Owner, "StartVelocity: " + StartVelocity.Size());
			// CodyPrint(Owner, "InputVelocity: " + FrameMovement.Velocity.Size());

			// DebugDrawVelocity(SplineDirectionVelocity, FLinearColor::Red);
			// DebugDrawVelocity(SideVelocity, FLinearColor::Blue);
			// DebugDrawVelocity(TotalVelocity, FLinearColor::Yellow);			
		}
	}

	void SlopeDebugArrow(FVector Delta, FLinearColor Color = FLinearColor::Red, FVector Offset = FVector::ZeroVector, float ArrowSize = 5.f)
	{
		FVector Start = MoveComp.OwnerLocation + Offset;
		FVector End = Start + Delta;
		System::DrawDebugArrow(Start, End, ArrowSize, Color);
	}

	void UpdateFacingRotation(FVector TotalVelocity, FVector SplineRightVector, FVector InputVector)
	{
		FVector FacingDirection = (TotalVelocity.GetSafeNormal() + (SplineRightVector * SplineRightVector.DotProduct(InputVector) * 1.5f)).GetSafeNormal();
		MoveComp.SetTargetFacingDirection(FacingDirection, 2.f);

		FVector UpDirection = MoveComp.WorldUp;
		if (MoveComp.DownHit.bBlockingHit)
		{
			UpDirection = MoveComp.DownHit.Normal;
		}

		FRotator Rotation = Math::ConstructRotatorFromUpAndForwardVector(FacingDirection, UpDirection);
		Player.RootOffsetComponent.OffsetRotationWithSpeed(Rotation, 1.f);
	}

	void UpdateBlendSpaceValue(FVector HorizontalVelocity, FVector VerticalVelocity)
	{
		FVector LocalHorizontalVelocity = MoveComp.OwnerRotation.UnrotateVector(HorizontalVelocity);
		FVector LocalVerticalVelocity = MoveComp.OwnerRotation.UnrotateVector(VerticalVelocity);

		USplineSlopeSlidingTurnSettings TurnSettings = USplineSlopeSlidingTurnSettings::GetSettings(Owner);
		USplineSlopeSlidingForwardSpeedSettings ForwardSettings = USplineSlopeSlidingForwardSpeedSettings::GetSettings(Owner);

		FVector2D NewBlendSpaceValues;
		NewBlendSpaceValues.X = (LocalHorizontalVelocity.Size() / TurnSettings.MaxSideSpeed) * FMath::Sign(LocalHorizontalVelocity.Y);
		NewBlendSpaceValues.Y = (LocalVerticalVelocity.Size() / ForwardSettings.MaxForwardSpeed) * FMath::Sign(LocalVerticalVelocity.X);
		Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceX, NewBlendSpaceValues.X);
		Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceY, NewBlendSpaceValues.Y);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
		}

		return "Not Falling";
	}
};
