import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.MagneticSnowProjectile;
import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.SnowCannonActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetSnowCanonComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetBasePad;
import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.ShotBySnowCannonComponent;
import Vino.Pickups.PlayerPickupComponent;

class USnowCannonShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

    UPrimitiveComponent MeshComponent;
	UMagnetSnowCanonComponent MagnetComponent;
	ASnowCannonActor SnowCannon;

	TArray<AMagneticSnowProjectile> CurrentProjectiles;
	TArray<UShotBySnowCannonComponent> CurrentComps;

	TArray<FName> NetPendingProjectileExplosions;

	int CurrentProjectileIndex = 0;
	int CurrentBasePadIndex = 0;

	float OriginalSelectiveDistance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        MagnetComponent = UMagnetSnowCanonComponent::Get(Owner);
        MeshComponent = Cast<UPrimitiveComponent>(Owner.RootComponent);
		SnowCannon = Cast<ASnowCannonActor>(Owner);
		
		if(SnowCannon.ContainedProjectiles.Num() <= 0)
		{
			for(int i = 0; i < SnowCannon.NumberOfContainedProjectiles; i++)
			{
				AMagneticSnowProjectile Projectile = Cast<AMagneticSnowProjectile>(SpawnActor(SnowCannon.ProjectileClass, Level = Owner.Level));
				Projectile.MakeNetworked(MagnetComponent, i);
				Projectile.SetControlSide(MagnetComponent);

				Projectile.Initialize(SnowCannon, !SnowCannon.bIsPositive);
				Projectile.DeactivateProjectile();

				Projectile.OnSnowCannonProjectileHit.AddUFunction(this, n"ProjectileHit");
				SnowCannon.ContainedProjectiles.Add(Projectile);
			}
		}

		if(SnowCannon.ContainedBasePads.Num() <= 0)
		{
			for(int i = 0; i < SnowCannon.NumberOfSpawnableBasePads; i++)
			{
				AMagnetBasePad BasePad = Cast<AMagnetBasePad>(SpawnActor(SnowCannon.BasePadClass, bDeferredSpawn = true, Level = Owner.Level));
				BasePad.PerchCameraDistanceMultiplier = 2.3f;
				BasePad.AttractionActivationDistance *= 1.8f;
				BasePad.SetShotByCannon(true);
				OriginalSelectiveDistance = BasePad.MagneticCompMay.GetDistance(EHazeActivationPointDistanceType::Selectable);

				UShotBySnowCannonComponent Comp = Cast<UShotBySnowCannonComponent>(BasePad.CreateComponent(SnowCannon.ShotBySnowCannonComponentClass));

				BasePad.MakeNetworked(MagnetComponent, i);
				BasePad.SetControlSide(MagnetComponent);
				FinishSpawningActor(BasePad);

				if(SnowCannon.bIsPositive)
				{
					BasePad.OverridePolarity(EMagnetPolarity::Minus_Blue);
				}
				else
				{
					BasePad.OverridePolarity(EMagnetPolarity::Plus_Red);
				}

				BasePad.DeactivateAndHideBasePad();
				BasePad.AddCapability(SnowCannon.MagnetSlideCapabilityClass);
				BasePad.AddCapability(n"MagneticSnowCannonMagnetFreeFallCapability");
				BasePad.AddCapability(n"MagneticSnowCannonMagnetDestroyedCapability");

				// Increase disable component range
				BasePad.DisableComponent.AutoDisableRange = 20000.f;

				Comp.OnSnowCannonShotDestroyed.AddUFunction(this, n"ComponentDestroyed");

				SnowCannon.ContainedBasePads.Add(BasePad);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!WasActionStopped(n"PullingSnowCannon"))
            return EHazeNetworkActivation::DontActivate;
		
		if (SnowCannon.bInCooldown)
			return EHazeNetworkActivation::DontActivate;

		if (!SnowCannon.bThumperCocked)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"PullingSnowCannon"))
            return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddVector(n"SpawnLocation", SnowCannon.ShootLocation.WorldLocation);
		Params.AddVector(n"SpawnRotation", SnowCannon.FakeMagnetProjectile.WorldRotation.Euler());
		Params.AddVector(n"Direction", SnowCannon.ShootLocation.ForwardVector);
		Params.AddVector(n"TargetLocation", SnowCannon.Crosshair.WorldLocation);
		Params.AddVector(n"TargetRotation", SnowCannon.Crosshair.ForwardVector);

		if(SnowCannon.bValidAimTarget)
			Params.AddActionState(n"ValidAimTarget");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FVector SpawnLocation = ActivationParams.GetVector(n"SpawnLocation");
		FQuat SpawnRotation = FQuat::MakeFromEuler(ActivationParams.GetVector( n"SpawnRotation"));
		FVector Direction = ActivationParams.GetVector(n"Direction");
		FVector TargetLocation = ActivationParams.GetVector(n"TargetLocation");
		FQuat TargetRotation = ActivationParams.GetVector(n"TargetRotation").ToOrientationQuat();

		AMagneticSnowProjectile CurrentProjectile = SnowCannon.ContainedProjectiles[CurrentProjectileIndex];

		CurrentProjectile.ShootProjectile(SpawnLocation, SpawnRotation, TargetLocation, TargetRotation, Direction * SnowCannon.ProjectileSpeed, SnowCannon.ProjectileGravity, ActivationParams.GetActionState(n"ValidAimTarget"));
		CurrentProjectiles.Add(CurrentProjectile);

		CurrentProjectileIndex++;
		if(CurrentProjectileIndex >= SnowCannon.ContainedProjectiles.Num())
			CurrentProjectileIndex = 0;  
		
		Niagara::SpawnSystemAtLocation(SnowCannon.CannonShotEffect, SnowCannon.ShootLocation.WorldLocation);

		SnowCannon.OnShoot.Broadcast();
	}

	UFUNCTION()
	void ProjectileHit(AMagneticSnowProjectile Projectile, FHitResult Hit)
	{
		// Play impact sound
		Projectile.PlayImpactAudioEvent(CanMagnetAttachToSurface(Hit.Component));

		// Remove projectile actor from pool
		CurrentProjectiles.Remove(Projectile);

		if(HasControl())
		{
			// Test if suface was valid and spawn sliding magnet
			if(CanMagnetAttachToSurface(Hit.Component))
			{
				NetTeleportAndSetupBasePad(Hit, Projectile.Name);
			}
			// Projectile didn't hit a slideable surface
			else
			{
				if(Hit.Actor != nullptr && Hit.Actor.IsA(AHazePlayerCharacter::StaticClass()))
				{
					AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
					NetKillPlayer(HitPlayer.IsCody() ? EHazePlayer::Cody : EHazePlayer::May);
				}

				NetAddPendingProjectileExplosion(Projectile.Name);
			}
		}

		// Locally Sp4wn them aw3zum grAaFx omGz!
		if(NetPendingProjectileExplosions.FindIndex(Projectile.Name) >= 0)
		{
			NetPendingProjectileExplosions.Remove(Projectile.Name);
			ExplodeMagnet(Hit.Location, Projectile.ExploEvent);
		}
		else
		{
			Niagara::SpawnSystemAtLocation(SnowCannon.IceWallAttachEffect, Hit.Location, Hit.ImpactNormal.Rotation());
		}
	}

	UFUNCTION()
	void ComponentDestroyed(UShotBySnowCannonComponent Comp)
	{
		CurrentComps.Remove(Comp);
		AMagnetBasePad BasePad = Cast<AMagnetBasePad>(Comp.Owner);
		BasePad.DeactivateAndHideBasePad();
	}

	bool CanMagnetAttachToSurface(UPrimitiveComponent SurfaceComponent) const
	{
		if(SurfaceComponent == nullptr)
			return false;

		return SurfaceComponent.HasTag(n"IceMagnetSlideable");
	}

	UFUNCTION(NetFunction)
	void NetKillPlayer(EHazePlayer PlayerToMurder)
	{
		KillPlayer(Game::GetPlayer(PlayerToMurder), SnowCannon.PlayerDeathEffect);
	}

	UFUNCTION(NetFunction)
	void NetTeleportAndSetupBasePad(const FHitResult& CollisionHit, FName ProjectileName)
	{
		AMagnetBasePad CurrentBasePad = SnowCannon.ContainedBasePads[CurrentBasePadIndex];
		ResetBasePad(CurrentBasePad);
		CurrentBasePad.SetActorLocation(CollisionHit.ImpactPoint);
		CurrentBasePad.SetActorRotation(CollisionHit.ImpactNormal.Rotation());

		UShotBySnowCannonComponent CurrentComp =  UShotBySnowCannonComponent::Get(CurrentBasePad);
		CurrentComps.Add(CurrentComp);

		if(CollisionHit.Component != nullptr && CollisionHit.Component.HasTag(n"IceMagnetSlideable"))
		{
			CurrentComp.IceWall = CollisionHit;
			CurrentComp.CurrentState = EMagneticBasePadState::IceSliding;
		}
		else if(CollisionHit.Actor != nullptr && CollisionHit.Actor.RootComponent != nullptr && CollisionHit.Actor.RootComponent.HasTag(n"IceMagnetSlideable"))
		{
			CurrentComp.IceWall = CollisionHit;
			CurrentComp.CurrentState = EMagneticBasePadState::IceSliding;
		}

		CurrentBasePad.AttachToComponent(CollisionHit.Component, n"", EAttachmentRule::KeepWorld);
		CurrentBasePad.JumpFromPerchGravityMultiplier = 0.75f;
		CurrentBasePad.ActivateAndUnhideBasePad();

		CurrentBasePadIndex++;
		if(CurrentBasePadIndex >= SnowCannon.ContainedBasePads.Num())
			CurrentBasePadIndex = 0;
	}

	void ResetBasePad(AMagnetBasePad BasePad)
	{
		if(BasePad.MagneticCompCody.GetDistance(EHazeActivationPointDistanceType::Selectable) != OriginalSelectiveDistance)
			BasePad.MagneticCompCody.InitializeDistance(EHazeActivationPointDistanceType::Selectable, OriginalSelectiveDistance);

		if(BasePad.MagneticCompMay.GetDistance(EHazeActivationPointDistanceType::Selectable) != OriginalSelectiveDistance)
			BasePad.MagneticCompMay.InitializeDistance(EHazeActivationPointDistanceType::Selectable, OriginalSelectiveDistance);

		if(!BasePad.bUseLongJumpFromMagnetPerch)
			BasePad.bUseLongJumpFromMagnetPerch = true;

		if(UShotBySnowCannonComponent::Get(BasePad).CurrentState != EMagneticBasePadState::Idle)
		{
			BasePad.SetCapabilityActionState(n"SlideReset", EHazeActionState::ActiveForOneFrame);
			ExplodeMagnet(BasePad.ActorLocation, SnowCannon.ContainedProjectiles[CurrentProjectileIndex].ExploEvent);
		}
	}

	UFUNCTION(NetFunction)
	void NetAddPendingProjectileExplosion(FName ProjectileName)
	{
		NetPendingProjectileExplosions.Add(ProjectileName);
	}

	void ExplodeMagnet(FVector Location, UAkAudioEvent AudioEvent)
	{
		Niagara::SpawnSystemAtLocation(SnowCannon.ProjectileExplosionEffect, Location);

		TMap<FString, float> Rtpcs;
		Rtpcs.Add("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", -8.f);

		UHazeAkComponent::HazePostEventFireForgetWithRtpcs(AudioEvent, FTransform(Location), Rtpcs);
	}
}