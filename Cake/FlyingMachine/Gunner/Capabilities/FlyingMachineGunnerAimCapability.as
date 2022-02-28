import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.Gunner.FlyingMachineGunnerComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

class UFlyingMachineGunnerAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Gunner);
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 50;
	default CapabilityDebugCategory = FlyingMachineCategory::Gunner;

	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUser;
	UFlyingMachineGunnerComponent Gunner;

	AFlyingMachineTurret Turret;

	UHazeCameraComponent Camera;
	USceneComponent CameraPivot;

	// Network syncing
	float SyncTime = 0.f;
	const float SyncInterval = 0.05f;

	FRotator LastSyncedDesired;
	UPrimitiveComponent LastSyncedComponent;
	FVector LastSyncedComponentOffset;
	FHazeAcceleratedRotator SyncRotator;

	FFlyingMachineGunnerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Gunner = UFlyingMachineGunnerComponent::GetOrCreate(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Gunner.CurrentTurret == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Gunner.CurrentTurret == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Turret = Gunner.CurrentTurret;

		Camera = Turret.Camera;
		CameraPivot = nullptr;

		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 2.f;
		Player.ApplyCameraSettings(
			Turret.CameraSettings,
			BlendSettings,
			this,
			EHazeCameraPriority::Medium
		);
		Player.ActivateCamera(Camera, BlendSettings, this);

		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);

		// Get turret target direction
		FVector CameraTargetLoc = Player.GetViewLocation() + Player.GetViewRotation().ForwardVector * Settings.TargetTraceLength;
		FVector TurretForward = (CameraTargetLoc - Turret.TurretLocation);
		TurretForward.Normalize();

		Gunner.TargetAimDirection = TurretForward;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DeactivateCameraByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
		CameraUser.ClearAiming(this);

		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (Time::GetRealTimeSeconds() > SyncTime)
			{
				SyncTime += SyncInterval;

				// Find if we're aiming at something
				FVector Loc = Camera.GetWorldLocation();
				FVector Dir = Camera.GetForwardVector();
				TArray<AActor> IgnoreActors;

				FHitResult Hit;
				System::LineTraceSingle(Loc, Loc + Dir * Settings.TargetTraceLength, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, true);

				bool bFoundTarget = false;

				if (Hit.bBlockingHit && Hit.Actor != nullptr)
				{
					if (!Hit.Actor.IsNetworked())
					{
						Print(Hit.Actor.Name + " is not networked!", SyncInterval, Color = FLinearColor::Red);
					}
					else
					{
						// Cool! Send over the primitive and where we're aiming (relative to the component)
						FVector RelativeHitLocation =
							Hit.Component.WorldTransform.InverseTransformPosition(Hit.Location);

						// Sync dat!
						NetSyncAimTarget(Hit.Component, RelativeHitLocation);
						bFoundTarget = true;
					}
				}

				// If we didn't find a target, just sync the rotation
				if (!bFoundTarget)
				{
					// Just sync pure rotation
					NetSyncAimDesiredRotation(CameraUser.DesiredRotation);
				}
			}
		}
		else
		{
			FRotator TargetDesired;

			// OK! Are we aiming at something?
			if (LastSyncedComponent != nullptr)
			{
				// Get the world location of where we're aiming at it
				FVector AimTargetWorld = LastSyncedComponent.WorldTransform.TransformPosition(LastSyncedComponentOffset);

				FVector AimDirection = AimTargetWorld - Camera.WorldLocation;

				CameraUser.SetDesiredRotation(Math::MakeRotFromX(AimDirection));
				TargetDesired = Math::MakeRotFromX(AimDirection);
			}
			else
			{
				TargetDesired = LastSyncedDesired;
			}

			// Lerp it, so it isn't super janky!
			SyncRotator.AccelerateTo(TargetDesired, 0.15f, DeltaTime);
			CameraUser.DesiredRotation = SyncRotator.Value;
		}

		FRotator UserRotation = CameraUser.DesiredRotation;

		FVector CameraTargetLoc = Camera.WorldLocation + Camera.ForwardVector * Settings.TargetTraceLength;

		// Get turret target direction
		FVector TurretForward = (CameraTargetLoc - Turret.TurretLocation);
		TurretForward.Normalize();

		Gunner.TargetAimDirection = TurretForward;
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSyncAimTarget(UPrimitiveComponent Component, FVector RelativeOffset)
	{
		LastSyncedComponent = Component;
		LastSyncedComponentOffset = RelativeOffset;
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSyncAimDesiredRotation(FRotator Rotator)
	{
		LastSyncedComponent = nullptr;
		LastSyncedDesired = Rotator;
	}
}