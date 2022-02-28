import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.Flee.WaspBehaviourFlyAway;
import Peanuts.Audio.AudioStatics;

class AFallingBeeHiveActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UDecalComponent NestDecal;

	UPROPERTY(Attach = Mesh)
	UNiagaraSystem NestExplosionEffect;

	UPROPERTY()
	ASwarmActor Swarm;

	UPROPERTY(Meta = (MakeEditWidget))
	FTransform FallPosition;

	FVector StartDecalSize;

	UPROPERTY()
	float ScaleTransformFactor = 1.f;

	UPROPERTY()
	float FallSpeed = 100;

	UPROPERTY()
	bool bDebugStartFalling = false;

	UPROPERTY()
	bool bShouldTelegraph = true;

	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset BombAnimSettingsHighStiffness;

	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset BombAnimSettings;

	bool bIsFalling;
	FVector FallVector;
	float CurrentSpeed;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BeeHiveFallingAudioEvent;

	UPROPERTY()
	FHazeTimeLike FadeinTimelike;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BeeHiveHitGroundAudioEvent;

	UPROPERTY()
	UForceFeedbackEffect HitGroundForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> HitGroundCamShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
		if (!Swarm.IsActorDisabled(Swarm))
		{
			Swarm.DisableActor(Swarm);
		}

		AddCapability(n"FallingBeehiveAudioCapability");
		
		StartDecalSize = NestDecal.RelativeScale3D;

		if (bDebugStartFalling)
		{
			StartFalling();
		}

		FadeinTimelike.BindUpdate(this, n"DecalScaleUpdate");
	}

	UFUNCTION()
	void StartFalling(bool bHighStiffness = true)
	{
		SetActorHiddenInGame(false);
		NestDecal.SetHiddenInGame(false);

		FadeinTimelike.PlayFromStart();

		if (Swarm.IsAnyCapabilityActive(UWaspBehaviourFlyAwayCapability::StaticClass()))
		{
			Swarm.SetCapabilityActionState(n"StopFlyAway", EHazeActionState::Active);
		}

		if (Swarm.IsActorDisabled())
		{
			Swarm.EnableActor(Swarm);
		}

		FTransform MeshTransform = Mesh.WorldTransform;
		MeshTransform.SetScale3D(FVector::OneVector);
		Swarm.TeleportSwarm(MeshTransform);

		if (bHighStiffness)
		{
			Swarm.PlaySwarmAnimation(BombAnimSettingsHighStiffness, this, 0.0f);	
		}

		else
		{
			Swarm.PlaySwarmAnimation(BombAnimSettings, this, 0.0f);	
		}
		
		Swarm.AttachToComponent(Mesh, AttachmentRule = EAttachmentRule::SnapToTarget);
		
		FallVector = FVector::ZeroVector;
		Mesh.SetRelativeLocation(FVector::ZeroVector);
		Mesh.SetHiddenInGame(true);

		if (bShouldTelegraph)
		{
			System::SetTimer(this, n"TelegraphDone", 1, false, 0);
		}
		else
		{
			TelegraphDone();
		}

		HazeAkComp.HazePostEvent(BeeHiveFallingAudioEvent);

	}

	UFUNCTION()
	void DecalScaleUpdate(float Time)
	{
		FVector SmallDecalSize = StartDecalSize * 0.1f;
		NestDecal.RelativeScale3D = FMath::Lerp(SmallDecalSize, StartDecalSize, Time);
	}

	UFUNCTION()
	void TelegraphDone()
	{
		SetActorHiddenInGame(false);
		bIsFalling = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsFalling)
		{
			FVector WorldfallPos = Root.WorldTransform.TransformPosition(FallPosition.Location);

			float FallDist = Swarm.ActorLocation.Z - WorldfallPos.Z;

			if (FallDist < 50.f)
			{
				HitGround();
			}
			else
			{
				FallBehaviour(DeltaTime);
			}
		}
	}

	void FallBehaviour(float DeltaTime)
	{
		FallVector += Mesh.UpVector * -1 * FallSpeed * DeltaTime;
		CurrentSpeed = (Mesh.UpVector * -1 * FallSpeed * DeltaTime).Size();
		Mesh.SetWorldLocation(FallVector + Mesh.WorldLocation);
	}

	void HitGround()
	{
		Mesh.SetWorldLocation(ActorTransform.TransformPosition(FallPosition.Location));
		SetActorHiddenInGame(true);
		Niagara::SpawnSystemAtLocation(NestExplosionEffect, Mesh.WorldLocation);
		
		bIsFalling = false;
		FTransform MeshTransform = Mesh.WorldTransform;
		MeshTransform.Scale3D = FVector::OneVector * ScaleTransformFactor;
		
		Swarm.SetActorLocation(MeshTransform.Location);
		Swarm.TeleportSwarm(MeshTransform);
		Swarm.SetCapabilityActionState(n"SwarmActive", EHazeActionState::Active);

		NestDecal.SetHiddenInGame(true);

		HazeAkComp.HazePostEvent(BeeHiveHitGroundAudioEvent);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayForceFeedback(HitGroundForceFeedback, false, true, n"BeehiveImpact", 1.25f);
			Player.PlayCameraShake(HitGroundCamShake);
		}
	}

	void Stop()
	{
		Swarm.SetCapabilityActionState(n"SwarmActive", EHazeActionState::Inactive);
	}
}