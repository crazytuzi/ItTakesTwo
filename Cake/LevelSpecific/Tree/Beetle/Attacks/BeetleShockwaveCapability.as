import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetleShockwaveComponent;
import Cake.LevelSpecific.Tree.Beetle.Settings.BeetleSettings;
import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetlePlayerDamageEffect;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Tree.Beetle.Health.BeetleHealthComponent;
import Cake.LevelSpecific.Tree.Beetle.AIBeetle;

// Capability for updating Shockwave and detecting player hits
class UBeetleStartShockwaveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Shockwave");
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	UBeetleSettings Settings;
	UBeetleShockwaveComponent ShockwaveComp;
	UBeetleHealthComponent HealthComp;
	AAIBeetle Beetle;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Settings = UBeetleSettings::GetSettings(Owner);
		ShockwaveComp = UBeetleShockwaveComponent::Get(Owner);
		HealthComp = UBeetleHealthComponent::Get(Owner);
		Beetle = Cast<AAIBeetle>(Owner);	

        ensure((ShockwaveComp != nullptr) && (Settings != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ShockwaveComp.NumPendingShockwaves == 0)
			return EHazeNetworkActivation::DontActivate;

		// Never allow more than four active shockwaves at one time
		if (ShockwaveComp.Shockwaves.Num() > 3)
			return EHazeNetworkActivation::DontActivate;
		
		// No shockwaves when dead or disabled
		if (HealthComp.RemainingHealth <= 0.f)
		 	return EHazeNetworkActivation::DontActivate; 
		if (Owner.IsActorDisabled())
		 	return EHazeNetworkActivation::DontActivate;

       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Activation handles triggering only
       	return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		// Make sure we sync number of shock waves
		OutParams.AddNumber(n"PendingShockwaves", ShockwaveComp.NumPendingShockwaves);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Consume shockwave
		ShockwaveComp.NumPendingShockwaves--;
		
		// Clear pending shockwaves on remote side in case we switch control side
		if (!HasControl())
			ShockwaveComp.NumPendingShockwaves = 0; 

		// Start Shockwave where beetle is at on local side.
		FBeetleShockwave Shockwave;
		Shockwave.Origin = Owner.ActorTransform.TransformPosition(Settings.ShockwaveRelativeOrigin);
		Shockwave.Origin.Z = ShockwaveComp.ShockWaveHeight + Settings.ShockwaveRelativeOrigin.Z;
		Shockwave.MajorRadius = Settings.ShockwaveStartRadius;
		Shockwave.MinorRadius = Settings.ShockwaveThickness;
		Shockwave.Speed = Settings.ShockwaveExpansionSpeed;
		Shockwave.ExpirationTime = Time::GetGameTimeSeconds() + Settings.ShockwaveDuration;
		Shockwave.ValidTargets = Game::GetPlayers();

		if (ShockwaveComp.ShockwaveEffect != nullptr)
			Shockwave.Effect = Niagara::SpawnSystemAtLocation(ShockwaveComp.ShockwaveEffect, Shockwave.Origin, FRotator::ZeroRotator);

		Beetle.HazeAkComp.HazePostEvent(Beetle.ShockwaveEvent);

		if (ShockwaveComp.ShockwaveMesh != nullptr)
		{
			if (ShockwaveComp.AvailableMeshes.Num() == 0)
			{
				// Create a new mesh, detached from beetle
				Shockwave.MeshComp = UStaticMeshComponent::Create(Owner);
				Shockwave.MeshComp.StaticMesh = ShockwaveComp.ShockwaveMesh;
				Shockwave.MeshComp.DetachFromParent();
				Shockwave.MeshComp.SetCollisionProfileName(n"NoCollision");
				Shockwave.MeshComp.WorldRotation = FRotator::ZeroRotator;
				Shockwave.MeshComp.SetVisibility(true);	
			}
			else
			{
				// Reuse last available mesh comp
				Shockwave.MeshComp = ShockwaveComp.AvailableMeshes.Last();
				ShockwaveComp.AvailableMeshes.RemoveAt(ShockwaveComp.AvailableMeshes.Num() - 1);
			}
			Shockwave.MeshComp.SetHiddenInGame(false);
			Shockwave.MeshComp.WorldLocation = Shockwave.Origin;
			Shockwave.MeshComp.WorldScale3D = ShockwaveComp.GetShockwaveMeshScale(Shockwave.MajorRadius, Shockwave.MinorRadius);
		}

		ShockwaveComp.Shockwaves.Add(Shockwave);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayForceFeedback(ShockwaveComp.ShockwaveForceFeedback, false, true, n"BeetleShockwave");
			Player.PlayCameraShake(ShockwaveComp.ShockwaveCameraShake, 0.6f);
		}
    }
}

class UBeetleUpdateShockwavesCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Shockwave");
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	UBeetleSettings Settings;
	UBeetleShockwaveComponent ShockwaveComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Settings = UBeetleSettings::GetSettings(Owner);
		ShockwaveComp = UBeetleShockwaveComponent::Get(Owner);

        ensure((ShockwaveComp != nullptr) && (Settings != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ShockwaveComp.Shockwaves.Num() == 0)
			return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ShockwaveComp.Shockwaves.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;
       	return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurTime = Time::GetGameTimeSeconds();
		for (int i = ShockwaveComp.Shockwaves.Num() - 1; i >= 0; i--)
		{
			FBeetleShockwave& Shockwave = ShockwaveComp.Shockwaves[i];
			if (CurTime > Shockwave.ExpirationTime)
			{
				// Shockwave is done
				if (Shockwave.MeshComp != nullptr)
				{
					Shockwave.MeshComp.SetHiddenInGame(true);
					ShockwaveComp.AvailableMeshes.Add(Shockwave.MeshComp);
				}
				ShockwaveComp.Shockwaves.RemoveAt(i);
				continue;
			}

			// Active shockwave
			float PreviousRadius = Shockwave.MajorRadius;
			Shockwave.MajorRadius += Shockwave.Speed * DeltaTime;

			if (Shockwave.MeshComp != nullptr)
			{
				Shockwave.MeshComp.WorldScale3D = ShockwaveComp.GetShockwaveMeshScale(Shockwave.MajorRadius, Shockwave.MinorRadius);
			}

			// Check if any players are hit.
			for (int iTarget = Shockwave.ValidTargets.Num() - 1; iTarget >= 0; iTarget--)
			{
				if (IsHitting(Shockwave.ValidTargets[iTarget], PreviousRadius, Shockwave))
				{
					// Use targets crumb component as this does not affect the beetle itself in any way
					UHazeCrumbComponent HitCrumbComp = UHazeCrumbComponent::Get(Shockwave.ValidTargets[iTarget]);
					if (!ensure(HitCrumbComp != nullptr))
						continue;
					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.AddObject(n"Target", Shockwave.ValidTargets[iTarget]);
					CrumbParams.AddVector(n"Force", GetImpactForce(Shockwave.ValidTargets[iTarget], Shockwave));
					HitCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbHit"), CrumbParams);
					Shockwave.ValidTargets.RemoveAtSwap(iTarget);
				}
			}  
			
	#if EDITOR
			//ShockwaveComp.bHazeEditorOnlyDebugBool = true;
			if (ShockwaveComp.bHazeEditorOnlyDebugBool)
			{
				System::DrawDebugCircle(Shockwave.Origin, Shockwave.MajorRadius - Shockwave.MinorRadius, 40, FLinearColor::Red, 0.f, 5.f, FVector::ForwardVector, FVector::RightVector);
				System::DrawDebugCircle(Shockwave.Origin, Shockwave.MajorRadius + Shockwave.MinorRadius, 40, FLinearColor::Red, 0.f, 5.f, FVector::ForwardVector, FVector::RightVector);
			}
	#endif
		}
	}

	bool IsHitting(AHazePlayerCharacter Target, float InnerRadius, const FBeetleShockwave& Shockwave)
	{
		if (Target == nullptr)
			return false;

		// Only hit on control side
		if (!Target.HasControl())
			return false;

		// Don't hit deadites
		if (IsPlayerDead(Target))
			return false;

		// Above Shockwave?
		FVector TargetLoc = Target.ActorLocation;
		if (TargetLoc.Z > Shockwave.Origin.Z + Shockwave.MinorRadius)
			return false;

		// Outside outer radius?
		if (!Shockwave.Origin.IsNear(TargetLoc, Shockwave.MajorRadius + Shockwave.MinorRadius))
			return false;

		// Within inner radius?
		if (Shockwave.Origin.IsNear(TargetLoc, InnerRadius - Shockwave.MinorRadius))
			return false;

		// Between inner and outer radius, a hit!
		return true;
	}

	FVector GetImpactForce(AHazeActor Target, const FBeetleShockwave& Shockwave)
	{
		FVector Direction = (Target.ActorLocation - Shockwave.Origin);
		Direction.Z = FMath::Max(500.f, Direction.Z);
		return Direction.GetSafeNormal() * Settings.AttackForce;
	}

	UFUNCTION()
	void CrumbHit(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter Target = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Target"));
		if (Target == nullptr)
			return;

		Target.SetCapabilityAttributeVector(n"KnockdownDirection", CrumbData.GetVector(n"Force"));
		Target.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);

		AAIBeetle Beetle = Cast<AAIBeetle>(Owner);
		Target.PlayerHazeAkComp.HazePostEvent(Beetle.ShockwavePlayerHitEvent);

        // Do damage
		DamagePlayerHealth(Target, 0.5f, TSubclassOf<UPlayerDamageEffect>(UBeetlePlayerDamageEffect::StaticClass()));
	}
}