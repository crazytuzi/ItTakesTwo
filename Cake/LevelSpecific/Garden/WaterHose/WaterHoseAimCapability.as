import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.Sickle.Player.Sickle;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;
import Peanuts.Crosshair.WorldSpaceCircleWidget;
import Peanuts.Crosshair.WorldSpaceConstantSizeCircleWidget;
import Peanuts.Aiming.AutoAimStatics;

class UWaterHoseAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ActionNames::WeaponAim);
	default CapabilityTags.Add(n"WaterHose");
	default CapabilityTags.Add(n"WaterHoseAim");
	default CapabilityTags.Add(n"BlockedWhileGrinding");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::LastDemotable;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UWaterHoseComponent WaterHoseComp;
	UCameraUserComponent CameraUser;

	FHazeHitResult WaterTraceResult;
	float NextTraceTime = 0;
	bool bBlockedJumping = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		WaterHoseComp = UWaterHoseComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		WaterHoseComp.AimValue = 0;
		WaterHoseComp.AimDirection = FVector::ForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(bBlockedJumping && HasControl())
		{
			if(MoveComp.IsGrounded())
			{
				UnblockJumpTags();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::WeaponAim))
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(ActionNames::WeaponAim, true);
	
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(GardenSickle::Sickle, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(MovementSystemTags::TurnAround, this);

		// Setup Camera
		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = 0.5f;
		Player.ApplyCameraSettings(WaterHoseComp.AimCameraSettings, CamBlend, this);
		CameraUser.SetAiming(this);

		UHazeViewPoint ViewPoint = Player.GetViewPoint();

		FVector WidgetPosition = ViewPoint.GetViewLocation();
		WidgetPosition += (GetWantedAimDirection() * WaterHoseComp.WaterShootLength);

		WaterHoseComp.CurrentWidget.AutoAimTargetWorldLocation = WidgetPosition;
		WaterHoseComp.CurrentWidget.SetVisibility(ESlateVisibility::Visible);
		WaterHoseComp.CurrentWidget.OnAimStarted();
		WaterHoseComp.bWaterHoseActive = true;

		Player.SetCapabilityActionState(n"AudioEquipWaterHose", EHazeActionState::Active);

		// We block these to prevent the character from doing super moves
		if(HasControl() && !bBlockedJumping)
		{
			bBlockedJumping = true;
			Player.BlockCapabilities(n"AirJump", this);
			Player.BlockCapabilities(n"LongJump", this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(ActionNames::WeaponAim, false);
		
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(GardenSickle::Sickle, this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(MovementSystemTags::TurnAround, this);

		if(MoveComp.IsGrounded() 
			|| DeactivationParams.DeactivationReason != ECapabilityStatusChangeReason::Natural)
		{
			UnblockJumpTags();
		}

		CameraUser.ClearAiming(this);	
		Player.ClearCameraSettingsByInstigator(this, 1.f);
		
		WaterHoseComp.CurrentWidget.bHasAutoAimTarget = false;
		WaterHoseComp.CurrentWidget.SetVisibility(ESlateVisibility::Collapsed);

		WaterHoseComp.bWaterHoseActive = false;
		WaterHoseComp.AimValue = 0;
		WaterHoseComp.AimDirection = FVector::ForwardVector;
		WaterHoseComp.WaterShootDirection = FVector::ForwardVector;
		WaterHoseComp.WaterShootValue = 0;
		WaterHoseComp.WaterVelocity = FVector::ZeroVector;	
		WaterTraceResult = FHazeHitResult();
		NextTraceTime = 0;

		Player.SetCapabilityActionState(n"AudioUnEquipWaterHose", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UHazeViewPoint ViewPoint = Player.GetViewPoint();
		WaterHoseComp.AimDirection = GetWantedAimDirection();

		FHazeTraceParams TraceParams = WaterHoseComp.GetProjectileTrace();
		FVector RealShootPoint = WaterHoseComp.GetNozzleExitPoint();
		FVector CameraPosition = ViewPoint.GetViewLocation();
		FVector PositionOffset = Math::ConstrainVectorToDirection(RealShootPoint - CameraPosition, WaterHoseComp.AimDirection);

		TraceParams.From =  CameraPosition + PositionOffset;
		TraceParams.To = CameraPosition + (WaterHoseComp.AimDirection * WaterHoseComp.WaterShootLength);

		// Debug
		if(IsDebugActive())
			TraceParams.DebugDrawTime = 0;

		// Update the water tracing so we can tweak the shooting from the impact
		if(Time::GetGameTimeSeconds() > NextTraceTime)
		{
			TraceParams.Trace(WaterTraceResult);
			NextTraceTime = Time::GetGameTimeSeconds() + (1.f/15.f);
		}
		
		WaterHoseComp.CurrentWidget.bHasAutoAimTarget = false;
		FVector ShootToPosition = TraceParams.To;
		WaterHoseComp.CurrentWidget.AutoAimTargetWorldLocation = ShootToPosition;

		if(WaterTraceResult.bBlockingHit && WaterTraceResult.Actor != nullptr)
		{
			ShootToPosition = WaterTraceResult.ImpactPoint;

			// If we found a water impact component, force the water to go to that
			auto WaterComp = UWaterHoseImpactComponent::Get(WaterTraceResult.Actor);
			if(WaterComp != nullptr && WaterComp.ValidateImpact(WaterTraceResult.Component))
			{
				WaterHoseComp.CurrentWidget.bHasAutoAimTarget = true;
				if(WaterComp.ImpactValidation != EWaterImpactType::EntireActor)
				{
					ShootToPosition = WaterComp.GetTransformFor(Player).Location;		
					WaterHoseComp.CurrentWidget.AutoAimTargetWorldLocation = ShootToPosition;
				}
			}
		}

		const FVector ShootFromPosition = WaterHoseComp.GetNozzleExitPoint();
		const float HeightAlpha = FMath::Min(ShootFromPosition.Distance(ShootToPosition) / WaterHoseComp.WaterShootLength, 1.f);
		const float ShootHeight = FMath::Lerp(10.f, 500.f, FMath::Pow(HeightAlpha, 1.5f));

		FOutCalculateVelocity Result = CalculateParamsForPathWithHeight(
			ShootFromPosition, 
			ShootToPosition, 
			WaterHoseComp.WaterGravity, 
			ShootHeight, 
			-1, 
			MoveComp.WorldUp);

		WaterHoseComp.WaterLifeTime = WaterTraceResult.bBlockingHit ? Result.Time * 2 : WaterHoseComp.MaxLifeTime;
		WaterHoseComp.WaterVelocity = Result.Velocity;

		// Animation
		if(WaterHoseComp.WaterVelocity.IsNearlyZero())
			WaterHoseComp.WaterShootDirection = WaterHoseComp.AimDirection;	
		else
			WaterHoseComp.WaterShootDirection = WaterHoseComp.WaterVelocity.GetSafeNormal();		

		WaterHoseComp.AimValue = WaterHoseComp.AimDirection.DotProduct(MoveComp.WorldUp);
		WaterHoseComp.WaterShootValue = WaterHoseComp.WaterShootDirection.DotProduct(MoveComp.WorldUp);
		
		MoveComp.ForceActorRotationWithoutUpdatingMovement(CameraUser.DesiredRotation);
	}

	FVector GetWantedAimDirection() const
	{
		// We offset the shooting a little bit up
		FQuat OffsetQuat = WaterHoseComp.ShootOffsetRotation.Quaternion();
		FQuat FinalRotation = CameraUser.DesiredRotation.Quaternion() * OffsetQuat;
		FRotator WantedCameraRotation = FinalRotation.Rotator();
		return WantedCameraRotation.Vector();
	}

	void UnblockJumpTags()
	{
		if(!bBlockedJumping)
			return;

		bBlockedJumping = false;
		Player.UnblockCapabilities(n"AirJump", this);
		Player.UnblockCapabilities(n"LongJump", this);
	}
}