import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightNames;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.MovementSystemTags;
import Peanuts.Aiming.AutoAimStatics;
import Peanuts.Animation.AnimationStatics;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;

class USnowballFightAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(SnowballFightTags::Aim);
	default CapabilityTags.Add(n"SnowGlobeSideContent");
	default CapabilityTags.Add(n"SnowballFight");

	AHazePlayerCharacter Player;
	USnowballFightComponent SnowballFightComponent;
	UHazeMovementComponent MoveComp;
	UHazeActiveCameraUserComponent CameraUser;

	USnowballFightCrosshairWidget Widget;

	bool HasAimTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SnowballFightComponent = USnowballFightComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SnowballFightComponent == nullptr)
	        return EHazeNetworkActivation::DontActivate;

	    if (!IsActioning(ActionNames::WeaponAim))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SnowballFightComponent == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

	    if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CameraUser.SetAiming(this);
		Player.ApplyCameraSettings(SnowballFightComponent.AimCameraSettings, FHazeCameraBlendSettings(1.f), this, EHazeCameraPriority::Medium);

		// Player.BlockCapabilities(n"CharacterFacing", this);
		Player.BlockCapabilities(MovementSystemTags::TurnAround, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeVault, this);
		Player.BlockCapabilities(FMagneticTags::MagneticCapabilityTag, this);

		Widget = Cast<USnowballFightCrosshairWidget>(Player.AddWidget(SnowballFightComponent.CrosshairWidgetClass));
		SnowballFightComponent.AimWidget = Widget;
		
		Widget.UpdateAmmo(SnowballFightComponent.CurrentSnowballAmount, true);
		SnowballFightComponent.bIsAiming = true;

		if (SnowballFightComponent.bHaveCompletedTutorial)
			return;

		SnowballFightComponent.RemovePrompts(Player);	
		SnowballFightComponent.ShowRightPrompt(Player);
	}		
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CameraUser.ClearAiming(this);
		Player.ClearCameraSettingsByInstigator(this);

		// Player.UnblockCapabilities(n"CharacterFacing", this);
		Player.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeVault, this);
		Player.UnblockCapabilities(FMagneticTags::MagneticCapabilityTag, this);

		Player.RemoveWidget(Widget);
		Widget = nullptr;

		SnowballFightComponent.bIsAiming = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SnowballFightComponent.AimTargetComponent = nullptr;

		FRotator ControlRotation = Player.GetControlRotation();
		FVector CameraLocation = Player.GetPlayerViewLocation();
		FVector CameraForwardVector = Player.ControlRotation.ForwardVector;

		// Forward camera offset by distance to player, ensures we're never aiming behind the player
		const float OffsetDistance = (CameraLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector).Size();
		CameraLocation += CameraForwardVector * OffsetDistance;

		// NOTE: OffsetDistance subtracted from default MinimumDistance to make up for offset
		FAutoAimLine AutoAim = GetAutoAimForTargetLine(Player, CameraLocation, CameraForwardVector, 1000.f - OffsetDistance, SnowballFightComponent.MaxRange, true);
		FVector HudAimTarget;

		if (AutoAim.bWasAimChanged)
		{
			HudAimTarget = AutoAim.AutoAimedAtPoint;

			Widget.HasAimTarget = true;

			FHazeTraceParams TraceParams;

			TraceParams.InitWithCollisionProfile(n"BlockAll");
			TraceParams.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
			TraceParams.SetToLineTrace();
			TraceParams.IgnoreActor(Player);

			TraceParams.From = Player.ActorCenterLocation + FVector(0.f, 0.f, 100.f);
			TraceParams.To = TraceParams.From + CameraForwardVector * 200.f;

			FHazeHitResult HitFromPlayer;

			if(HasControl())
			{
				if (TraceParams.Trace(HitFromPlayer))
				{
					AHazePlayerCharacter IsPlayer = Cast<AHazePlayerCharacter>(HitFromPlayer.Actor);

					if (IsPlayer != nullptr)
					{
						SnowballFightComponent.AimTargetComponent = AutoAim.AutoAimedAtComponent;
						SnowballFightComponent.AimTarget = AutoAim.AutoAimedAtComponent.WorldLocation;
						SnowballFightComponent.bIsWithinCollision = false;
					}
					else
					{
						SnowballFightComponent.AimTarget = HitFromPlayer.ImpactPoint;
						SnowballFightComponent.bIsWithinCollision = true;
					}
				}
				else
				{
					SnowballFightComponent.AimTargetComponent = AutoAim.AutoAimedAtComponent;
					SnowballFightComponent.AimTarget = AutoAim.AutoAimedAtComponent.WorldLocation;
					SnowballFightComponent.bIsWithinCollision = false;
				}

				AActor TargetActor = AutoAim.AutoAimedAtComponent.Owner;
				SnowballFightComponent.TargetRelativeLocation = TargetActor.ActorTransform.InverseTransformPosition(AutoAim.AutoAimedAtPoint);
			}
		}
		else
		{
			SnowballFightComponent.bIsWithinCollision = false;
			Widget.HasAimTarget = false;

			FHitResult Hit;
			FHitResult HitFromPlayerToTarget;

			TArray<AActor> ActorsToIgnore;
			ActorsToIgnore.Add(Player);

			FVector TraceStart = CameraLocation;
			FVector TraceEnd = CameraLocation + CameraForwardVector * SnowballFightComponent.MaxRange;

			FVector TraceEndFromPlayer = CameraLocation + CameraForwardVector * 200.f;
			FVector PlayerTraceStart = Player.ActorCenterLocation;

			System::LineTraceSingle(TraceStart, TraceEnd, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

			FHazeTraceParams TraceParams;

			TraceParams.InitWithCollisionProfile(n"BlockAll");
			TraceParams.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
			TraceParams.SetToLineTrace();
			TraceParams.IgnoreActor(Player);

			TraceParams.From = PlayerTraceStart;
			TraceParams.To = TraceEndFromPlayer;

			FHazeHitResult HitFromPlayer;

			if (Hit.bBlockingHit)
			{
				if(HasControl())
				{
					SnowballFightComponent.bMaxRangeAim = false;
					SnowballFightComponent.bIsWithinCollision = false;

					if (TraceParams.Trace(HitFromPlayer))
					{
						SnowballFightComponent.AimTarget = HitFromPlayer.ImpactPoint;
						SnowballFightComponent.bIsWithinCollision = true;
					}
					else
						SnowballFightComponent.AimTarget = Hit.Location;
				}

				HudAimTarget = Hit.Location;
			}
			else
			{
				if(HasControl())
				{
					SnowballFightComponent.bMaxRangeAim = true;
					SnowballFightComponent.AimTarget = TraceEnd;
				}
				HudAimTarget = TraceEnd;
			}
		}

		FVector2D AimScreenPosition;
		SceneView::ProjectWorldToViewpointRelativePosition(Player, HudAimTarget, AimScreenPosition);
		FVector LerpedVector = FMath::VInterpTo(FVector(Widget.AimScreenPosition.X, Widget.AimScreenPosition.Y, 0.f), FVector(AimScreenPosition.X, AimScreenPosition.Y, 0.f), DeltaTime, 10.f);
		Widget.AimScreenPosition = FVector2D(LerpedVector.X, LerpedVector.Y);
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		if (SnowballFightComponent != nullptr)
			SnowballFightComponent.RemovePrompts(Player);
	}
};