import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Dash.CharacterDashSettings;
import Vino.Movement.Dash.CharacterDashComponent;
import Vino.Movement.Jump.AirJumpsComponent;
import Vino.Movement.Capabilities.WallSlide.WallSlideNames;
import Rice.Math.MathStatics;
import Vino.Movement.Capabilities.Sliding.CharacterSplineSlopeSlidingComponent;

class UCharacterSplopeSlopeAirDashCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"DashAction");
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 140;
	default SeperateInactiveTick(ECapabilityTickGroups::ActionMovement, 110);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCharacterDashComponent DashComp;
	UCharacterAirJumpsComponent AirJumpsComp;
	UCharacterAirDashSettings AirDashSettings;

	UCharacterSlopeSlideComponent SlideComp;

	FHazeAcceleratedFloat HorizontalSpeed;
	FHazeAcceleratedFloat VerticalSpeed;

	// Calculated on activate using distance over duration
	float Deceleration = 0.f;

	float DurationAlpha;

	FVector DashDirection = FVector::ZeroVector;
	FVector GravitySpeed = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		DashComp = UCharacterDashComponent::GetOrCreate(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);		
		AirDashSettings = UCharacterAirDashSettings::GetSettings(Owner);

		SlideComp = UCharacterSlopeSlideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (SlideComp.GuideSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(WasActionStarted(ActionNames::MovementDash))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if (SlideComp.GuideSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
			Player.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.f), this, EHazeCameraPriority::Low);
		Player.ApplyPivotLagMax(FVector(200.f, 200.f, 800.f), this, EHazeCameraPriority::Low);

		FVector SplineForwardDirection = FVector::ZeroVector;
		FVector RightVector = FVector::ZeroVector;
		SlideComp.GetCurrentDirectionAlongSpline(MoveComp, SplineForwardDirection, RightVector, false);

		DashDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (DashDirection.IsNearlyZero())
		{
			DashDirection = SplineForwardDirection.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		}

		if (DashDirection.DotProduct(SplineForwardDirection) < 0.f)
			DashDirection = RightVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * FMath::Sign(DashDirection.DotProduct(RightVector));

		float ScaleValue = 1.f;
		float SplineDot = DashDirection.DotProduct(Owner.GetControlRotation().ForwardVector);
		if (SplineDot > 0.5f)
			ScaleValue = 0.5f;

		HorizontalSpeed.Value = 2500.f * ScaleValue;
		HorizontalSpeed.Velocity = 500.f;

		VerticalSpeed.Value = 0.f;
		VerticalSpeed.Velocity = 0.f;

		GravitySpeed = FVector::ZeroVector;

		AirJumpsComp.ConsumeDash();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DashComp.DashActiveDuration = 0.f;
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		DashComp.DashActiveDuration += DeltaTime;

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"AirDash");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"AirDash");
			
			CrumbComp.LeaveMovementCrumb();	
		}
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			FVector SplineForwardDirection = FVector::ZeroVector;
			FVector RightVector = FVector::ZeroVector;

			SlideComp.GetCurrentDirectionAlongSpline(MoveComp, SplineForwardDirection, RightVector, false);

			HorizontalSpeed.AccelerateTo(1500.f, 1.f, DeltaTime);

			float DashSpeed = HorizontalSpeed.Value;
			//DashSpeed = DashSpeed * (1.f - SplineForwardDirection.DotProduct(DashDirection));

			FVector Velocity = DashDirection * DashSpeed;


			GravitySpeed += MoveComp.Gravity * DeltaTime / 2.f;

			float SplineSpeed = SlideComp.CalculateSpeedInSplineDirection(MoveComp, SplineForwardDirection, FVector::ZeroVector, DeltaTime);
			FVector SplineVelocity = SplineForwardDirection * SplineSpeed;

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.ApplyVelocity(GravitySpeed);
			FrameMove.ApplyVelocity(SplineVelocity);
			FrameMove.OverrideStepDownHeight(5.f);	
			FrameMove.FlagToMoveWithDownImpact();
			FrameMove.ApplyTargetRotationDelta(); 
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
		
	}

	float GetDashSpeed(float DeltaTime)
	{
		float SpeedAlpha = FMath::Pow(DurationAlpha, AirDashSettings.SpeedPow);
		float OldSpeed = FMath::Lerp(AirDashSettings.StartSpeed, AirDashSettings.EndSpeed, SpeedAlpha);		

		return OldSpeed;
	}
}
