import Vino.Interactions.InteractionComponent;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.SqueezeBox.SqueezeBoxProjectile;

event void FOnWallShielded();
event void FOnWallKilledPlayer(AHazePlayerCharacter Player);

class ASqueezeBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	USceneComponent CenterCollisionPos;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SqueezeBoxMesh;
	default SqueezeBoxMesh.bUseDisabledTickOptimizations = true;
	default SqueezeBoxMesh.DisabledVisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;

	UPROPERTY(DefaultComponent)
	UArrowComponent ProjectileSpawnLocation;
	UPROPERTY(DefaultComponent)
	UArrowComponent ProjectileEndLocation;
	UPROPERTY()
	TSubclassOf<ASqueezeBoxProjectile> Projectile;
	AActor ProjectileSpawned;

	UPROPERTY(DefaultComponent, Attach = SqueezeBoxMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionLeftExtraCollision;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionRightExtraCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionLeftCollision;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionLeftArmCollision;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionLeftForeArmCollision;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionLeftHandCollision;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionMiddleCollision;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionRightCollision;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionRightArmCollision;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionRightForeArmCollision;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent AccordionRightHandCollision;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisable;
	default HazeDisable.bAutoDisable = true;
	default HazeDisable.AutoDisableRange = 45000.f;

	TArray<UStaticMeshComponent> ImpactMeshArray;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent Push1AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent Push2AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent Push3AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent Retract1AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent Retract2AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent Retract3AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpawnProjectileAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AccordionBlastEvent;


	UPROPERTY()
	FOnWallShielded OnWallShielded;
	UPROPERTY()
	FOnWallKilledPlayer OnWallKilledPlayer;

	float ProjectileVelocity = 2000.f;
	float ProjectileDuration = 8.75f;

	FHazeAcceleratedFloat AcceleratedFloatX;
	FHazeAcceleratedFloat AcceleratedFloatY;

	private float LastHorizontalMovementRtpcValue;

	float SpawnOneProjectileTimer;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffectTouchAccordion;

	UPROPERTY()
	AActor FadeHeightActorLocation;

	UPROPERTY()
	UBlendSpace MHAnimation;

	int ProjectilesSpawned = 0;
	bool bShouldRetractAccordion = false;
	bool bStartedShootingProjectiles = false;

	int NetWorkedProjectileSpawned = 0;
	bool bActive = false;
	float X;
	float Y;
	float MaxAmountOfProjectilePatterns = 4;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedFloatX.Value = 0.9;
		AcceleratedFloatY.Value = 0.3;
		SqueezeBoxMesh.SetBlendSpaceValues(AcceleratedFloatX.Value, AcceleratedFloatY.Value, false);

		ImpactMeshArray.Add(AccordionLeftExtraCollision);
		ImpactMeshArray.Add(AccordionRightExtraCollision);
		ImpactMeshArray.Add(AccordionLeftCollision);
		ImpactMeshArray.Add(AccordionLeftArmCollision);
		ImpactMeshArray.Add(AccordionLeftForeArmCollision);
		ImpactMeshArray.Add(AccordionLeftHandCollision);
		ImpactMeshArray.Add(AccordionMiddleCollision);
		ImpactMeshArray.Add(AccordionRightCollision);
		ImpactMeshArray.Add(AccordionRightArmCollision);
		ImpactMeshArray.Add(AccordionRightForeArmCollision);
		ImpactMeshArray.Add(AccordionRightHandCollision);

		AccordionLeftExtraCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"LeftHand"), EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		AccordionRightExtraCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"RightHand"), EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		AccordionLeftCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"LeftAccordion"), EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		AccordionLeftArmCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"LeftArm"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		AccordionLeftForeArmCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"LeftForeArm"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		AccordionLeftHandCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"LeftHand"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		AccordionMiddleCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"MiddleAccordion"), EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		AccordionRightCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"RightAccordion"), EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		AccordionRightArmCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"RightArm"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		AccordionRightForeArmCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"RightForeArm"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		AccordionRightHandCollision.AttachToComponent(SqueezeBoxMesh, SqueezeBoxMesh.GetSocketBoneName(n"RightHand"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);

		PlayBlendSpace(MHAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SqueezeBoxMesh.SetBlendSpaceValues(AcceleratedFloatX.Value, AcceleratedFloatY.Value, false);

		if(bActive == true)
		{
			for(auto Player: Game::GetPlayers())
			{
				float Dist = CenterCollisionPos.GetWorldLocation().DistSquared(Player.GetActorLocation());

				if(Dist > FMath::Square(6500))
					continue;
				
				auto PlayerMovementState = Player.MovementComponent.GetImpacts();

				for(auto Collision: ImpactMeshArray)
				{
					if(PlayerMovementState.ForwardImpact.Component == Collision 
						or PlayerMovementState.DownImpact.Component == Collision 
						or  PlayerMovementState.UpImpact.Component == Collision)
					{
						Player.KillPlayer(DeathEffectTouchAccordion);
							break;
					}
				}
			}

			if(ProjectilesSpawned == 0)
			{
				if(bShouldRetractAccordion == false)
					AnimationShootOneProjectile(DeltaTime);
				else
					AnimationChargeUpOneProjectile(DeltaTime);

				if(bStartedShootingProjectiles == false)
				{
					bStartedShootingProjectiles = true;
					StartSpawnOneProjectile();
					HazeAkComp.HazePostEvent(AccordionBlastEvent);
				}
			}
			if(ProjectilesSpawned == 1)
			{
				if(bShouldRetractAccordion == false)
					AnimationShootTwoProjectile(DeltaTime);
				else
					AnimationChargeUpTwoProjectile(DeltaTime);

				if(bStartedShootingProjectiles == false)
				{
					bStartedShootingProjectiles = true;
					StartSpawnTwoProjectile();
					HazeAkComp.HazePostEvent(AccordionBlastEvent);
				}
			}
			if(ProjectilesSpawned == 2)
			{
				if(bShouldRetractAccordion == false)
					AnimationShootOneProjectile(DeltaTime);
				else
					AnimationChargeUpOneProjectile(DeltaTime);

				if(bStartedShootingProjectiles == false)
				{
					bStartedShootingProjectiles = true;
					StartSpawnOneProjectile();
					HazeAkComp.HazePostEvent(AccordionBlastEvent);
				}
			}
			if(ProjectilesSpawned == 3)
			{
				if(bShouldRetractAccordion == false)
					AnimationShootOneProjectile(DeltaTime);
				else
					AnimationChargeUpOneProjectile(DeltaTime);

				if(bStartedShootingProjectiles == false)
				{
					bStartedShootingProjectiles = true;
					StartSpawnOneProjectile();
					HazeAkComp.HazePostEvent(AccordionBlastEvent);
				}
			}
			if(ProjectilesSpawned == 4)
			{
				if(bShouldRetractAccordion == false)
					AnimationShootTwoProjectile(DeltaTime);
				else
					AnimationChargeUpTwoProjectile(DeltaTime);

				if(bStartedShootingProjectiles == false)
				{
					bStartedShootingProjectiles = true;
					StartSpawnTwoProjectile();
					HazeAkComp.HazePostEvent(AccordionBlastEvent);
				}
			}

			UHazeAkComponent::HazeSetGlobalRTPCValue("RTPC_Classic_Accordeon", FMath::Sign(AcceleratedFloatX.Velocity));
		}
	}


	UFUNCTION()
	void StartSpawnOneProjectile()
	{
		System::SetTimer(this, n"SpawnProjectile", 0.9f, false);
		System::SetTimer(this, n"SpawnOneProjectileRetract", 1.f, false);
		HazeAkComp.HazePostEvent(Push1AudioEvent);
	}
	UFUNCTION()
	void SpawnOneProjectileRetract()
	{
		bShouldRetractAccordion = true;
		System::SetTimer(this, n"SpawnOneProjectileRetractStop", 2.0f, false);
		HazeAkComp.HazePostEvent(Retract1AudioEvent);
	}	
	UFUNCTION()
	void SpawnOneProjectileRetractStop()
	{
		bShouldRetractAccordion = false;
		bStartedShootingProjectiles = false;

		if(ProjectilesSpawned != MaxAmountOfProjectilePatterns)
			ProjectilesSpawned ++;	
		else
		{
			ProjectilesSpawned = 0;
		}
	}
	UFUNCTION()
	void AnimationShootOneProjectile(float DeltaTime)
	{
		AcceleratedFloatX.SpringTo(0, 5, 0.6, DeltaTime);
		AcceleratedFloatY.SpringTo(0.5, 1, 0.6, DeltaTime);
		//SqueezeBoxMesh.SetBlendSpaceValues(AcceleratedFloatX.Value, AcceleratedFloatY.Value, false);
	}
	UFUNCTION()
	void AnimationChargeUpOneProjectile(float DeltaTime)
	{
		AcceleratedFloatX.SpringTo(0.9, 2, 0.6, DeltaTime);
		AcceleratedFloatY.SpringTo(0.3, 1, 0.6, DeltaTime);
		//SqueezeBoxMesh.SetBlendSpaceValues(AcceleratedFloatX.Value, AcceleratedFloatY.Value, false);
	}


	UFUNCTION()
	void StartSpawnTwoProjectile()
	{
		System::SetTimer(this, n"SpawnProjectile2", 1.0f, false);
		//System::SetTimer(this, n"SpawnProjectile2", 1.5f, false);
		System::SetTimer(this, n"SpawnTwoProjectileRetract", 1.6f, false);
		HazeAkComp.HazePostEvent(Push2AudioEvent);
	}
	UFUNCTION()
	void SpawnTwoProjectileRetract()
	{
		bShouldRetractAccordion = true;
		System::SetTimer(this, n"SpawnTwoProjectileRetractStop", 2.0f, false);
		HazeAkComp.HazePostEvent(Retract2AudioEvent);
	}	
	UFUNCTION()
	void SpawnTwoProjectileRetractStop()
	{
		bShouldRetractAccordion = false;
		bStartedShootingProjectiles = false;

		if(ProjectilesSpawned != MaxAmountOfProjectilePatterns)
			ProjectilesSpawned ++;	
		else
		{
			ProjectilesSpawned = 0;
		}
	}
	UFUNCTION()
	void AnimationShootTwoProjectile(float DeltaTime)
	{
		AcceleratedFloatX.SpringTo(0, 2, 0.6, DeltaTime);
		AcceleratedFloatY.SpringTo(0.5, 1, 0.6, DeltaTime);
		//SqueezeBoxMesh.SetBlendSpaceValues(AcceleratedFloatX.Value, AcceleratedFloatY.Value, false);		
	}
	UFUNCTION()
	void AnimationChargeUpTwoProjectile(float DeltaTime)
	{
		AcceleratedFloatX.SpringTo(0.9, 2, 0.6, DeltaTime);
		AcceleratedFloatY.SpringTo(0.4, 1, 0.6, DeltaTime);
		//SqueezeBoxMesh.SetBlendSpaceValues(AcceleratedFloatX.Value, AcceleratedFloatY.Value, false);
	}


	
	UFUNCTION()
	void SetActive(bool Active)
	{
		if(Active == true)
		{
			bActive = true;
		}
		if(Active == false)
		{
			bActive = false;
		}
	}

	UFUNCTION()
	void SpawnProjectile()
	{
		if(Game::Cody.HasControl())
		{
			NetSpawnProjectile(50);
		}
	}
	UFUNCTION()
	void SpawnProjectile2()
	{
		if(Game::Cody.HasControl())
		{
			NetSpawnProjectile(100);
		}
	}
	UFUNCTION(NetFunction)
	void NetSpawnProjectile(float RandomUVFloat)
	{
		NetWorkedProjectileSpawned += 1;
		ProjectileSpawned = SpawnActor(Projectile, ProjectileSpawnLocation.GetWorldLocation(), GetActorRotation());
		ProjectileSpawned.MakeNetworked(this, NetWorkedProjectileSpawned);
		ASqueezeBoxProjectile NewProjectile = Cast<ASqueezeBoxProjectile>(ProjectileSpawned);
		NewProjectile.RandomUVFloat = RandomUVFloat;
		NewProjectile.FadeHeightLocation = FadeHeightActorLocation.GetActorLocation().Z;
		NewProjectile.ProjectileEndLocation = ProjectileEndLocation.GetWorldLocation();
		NewProjectile.SmoothVectorSync.Value = NewProjectile.GetActorLocation();
		NewProjectile.Velocity = ProjectileVelocity;
		NewProjectile.OnWallExploded.AddUFunction(this, n"WallShielded");
		NewProjectile.OnKilledPlayer.AddUFunction(this, n"WallKilledPlayer");
		HazeAkComp.HazePostEvent(SpawnProjectileAudioEvent);
	}

	UFUNCTION()
	void WallShielded()
	{
		OnWallShielded.Broadcast();
		PrintToScreen("Blocked", 3.f);
	}
	UFUNCTION()
	void WallKilledPlayer(AHazePlayerCharacter Player)
	{
		OnWallKilledPlayer.Broadcast(Player);
		PrintToScreen("Died", 3.f);
	}
}

