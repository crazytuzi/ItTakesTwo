import Cake.FlyingMachine.Gunner.FlyingMachineGunnerComponent;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.LevelSpecific.Tree.Escape.EscapeManager;

class UFlyingMachineGunnerFireCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Gunner);
	default CapabilityTags.Add(FlyingMachineTag::Fire);
	default TickGroup = ECapabilityTickGroups::LastDemotable;

	default CapabilityDebugCategory = FlyingMachineCategory::Gunner;

	AHazePlayerCharacter Player;
	UFlyingMachineGunnerComponent Gunner;

	AFlyingMachineTurret Turret;

	FFlyingMachineGunnerSettings Settings;
	float FireTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Gunner = UFlyingMachineGunnerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (Gunner.CurrentTurret == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkActivation::DontActivate;
		
		if (FireTimer > 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		/* We want to send over what/where we're shooting at so we shoot at the same thing */
		Turret = Gunner.CurrentTurret;
		FVector Loc = Turret.TurretLocation;
		FVector Direction = Turret.TurretForward;

		// If not auto-aiming, see what we're aiming at
		if (Gunner.AutoAimedTarget == nullptr)
		{
			FHitResult Hit;
			TArray<AActor> Ignore;

			// Line trace what we're looking at
			System::LineTraceSingle(Loc, Loc + Direction * Settings.TargetTraceLength, ETraceTypeQuery::Visibility, false, Ignore, EDrawDebugTrace::None, Hit, true);

			bool bTargetFound = false;

			if (Hit.bBlockingHit && Hit.Actor != nullptr)
			{
				if (!Hit.Actor.IsNetworked())
				{
					// If the thing we're shooting at is not networked, we can't send it over
					Print(Hit.Actor.GetName() + " is not networked, firing at it will break", 2.f, Color = FLinearColor::Red);
				}
				else
				{
					// Send the relative location we're shooting at
					FVector RelativeHitLocation = Hit.Component.WorldTransform.InverseTransformPosition(Hit.Location);

					Params.AddObject(n"TargetComponent", Hit.Component);
					Params.AddVector(n"TargetComponentOffset", RelativeHitLocation);
					Params.AddVector(n"TargetLocation", Hit.Location);

					bTargetFound = true;
				}
			}

			if (!bTargetFound)
			{
				// If we didn't find a target, just send the location we're looking at
				Params.AddVector(n"TargetLocation", Loc + Direction * Settings.TargetTraceLength);
			}
		}

		// If we ARE auto-aiming, just shoot straight at it
		else
		{
			Params.AddObject(n"TargetComponent", Gunner.AutoAimedTarget);
			Params.AddVector(n"TargetComponentOffset", FVector::ZeroVector);
			Params.AddVector(n"TargetLocation", Gunner.AutoAimedTarget.WorldLocation);
		}

		// Also send over the pooled projectile we will use for this firing
		auto Manager = GetEscapeManager();
		auto Projectile = Manager.GetFlakProjectile();

		Params.AddObject(n"Projectile", Projectile);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		// When this comes in after we (for example) start a cutscene, just dont shoot!
		// We're in a cutscene!
		// Don't disturb!
		if (Params.IsStale())
			return;

		// Might not be disabled if force-recycled or on slave side
		auto Projectile = Cast<AFlyingMachineFlakProjectile>(Params.GetObject(n"Projectile"));
		if (Projectile.bIsActive)
			Projectile.DeactivateProjectile();

		Turret = Gunner.CurrentTurret;
		FireTimer = 1.f / Settings.FlakFireFrequency;

		if (HasControl())
		{
			// Just fire where we're looking
			FVector TargetLocation = Params.GetVector(n"TargetLocation");
			Turret.FireAt(TargetLocation, Projectile);

			Player.PlayForceFeedback(Turret.FireFeedbackEffect, false, true, n"TurretFire");
		}
		else
		{
			FVector TargetLocation = Params.GetVector(n"TargetLocation");

			// Find if we're shooting at something, in that case shoot at it on the slave as well
			auto TargetComponent = Cast<UPrimitiveComponent>(Params.GetObject(n"TargetComponent"));
			Owner.SetCapabilityAttributeObject(n"TargetComponent", nullptr);

			if (TargetComponent != nullptr)
			{
				FVector ComponentOffset = Params.GetVector(n"TargetComponentOffset");
				TargetLocation = TargetComponent.WorldTransform.TransformPosition(ComponentOffset);
			}

			Turret.FireAt(TargetLocation, Projectile);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		FireTimer -= DeltaTime;
		Gunner.ReloadProgress = 1.f - FireTimer / (1.f / Settings.FlakFireFrequency);
	}
}