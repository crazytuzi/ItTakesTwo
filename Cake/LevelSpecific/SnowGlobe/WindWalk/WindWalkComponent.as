import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkVolume;
import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkNoWindVolume;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.Environment.HazeSphere;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;

event void FOnWindWalkDashEvent();

class UWindWalkComponent : UActorComponent
{
	bool bIsWindWalking;
	bool bIsHoldingOntoMagnetPole;

	const float Drag = 5.f;
	const float Acceleration = 3500.f;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem PlayerWindEffect;

	UNiagaraComponent PlayerWindEffectComponent;

	UPROPERTY()
	TSubclassOf<AHazeSphere> LocalFogClass;

	AHazeSphere LocalFogActor;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocomotionAssetMay;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocomotionAssetCody;

	AHazePlayerCharacter Player;

	UMagneticPlayerComponent PlayerMagnetComp;
	UMagneticPlayerComponent OtherPlayerMagnetComp;

	TArray<AWindWalkVolume> ActiveVolumes;
	TArray<AWindWalkNoWindVolume> ActiveNoWindVolumes;

	UPROPERTY()
	FVector CurrentForce;

	UPROPERTY()
	float CurrentScale;

	UPROPERTY()
	FVector GroundNormal;

	UPROPERTY()
	FVector ActiveMagnetLocation;

	FOnWindWalkDashEvent OnDash;

	UFUNCTION(BlueprintPure)
	bool IsBehindCover()
	{
		int ValidVolumes = ActiveNoWindVolumes.Num();

		for (auto NoWindVolume : ActiveNoWindVolumes)
		{
			if (NoWindVolume.bRequiresCrouching)
			{
				if (!Player.IsAnyCapabilityActive(MovementSystemTags::Crouch) || Player.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttractionPerchCapability))
				{
					ValidVolumes -= 1;
				}
			}
		}		

		return ValidVolumes > 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsInWindVolume()
	{
		int ValidVolumes = ActiveVolumes.Num();

		return ValidVolumes > 0;
	}	

	UFUNCTION(BlueprintPure)
	FVector GetWindForce()
	{
		int ValidVolumes = ActiveNoWindVolumes.Num();

		for (auto NoWindVolume : ActiveNoWindVolumes)
		{
			/*
			if (NoWindVolume.bRequiresCrouching && NoWindVolume.bRequiresCrouching != Player.IsAnyCapabilityActive(MovementSystemTags::Crouch))
			{
				ValidVolumes -= 1;
			}
			*/
			if (NoWindVolume.bRequiresCrouching)
			{
				if (!Player.IsAnyCapabilityActive(MovementSystemTags::Crouch) || Player.OtherPlayer.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttractionPerchCapability))
				{
					ValidVolumes -= 1;
				}
			}
		}

		if (ValidVolumes > 0)
			return FVector::ZeroVector;		

		FVector Force;

		for (auto WindVolume : ActiveVolumes)
		{
			if (WindVolume.bIsActive)
			{
			Force += WindVolume.WindDirection * WindVolume.WindForce * WindVolume.WindForceScale;
			}
		}

		return Force;
	}

	UFUNCTION(BlueprintPure)
	float GetWindForceScale()
	{
		float ForceScale = 0.f;

		for (auto Volume : ActiveVolumes)
		{
			ForceScale = FMath::Max(ForceScale, Volume.WindForceScale);
		}

		return ForceScale;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(GetOwner());
		PlayerWindEffectComponent = Niagara::SpawnSystemAttached(PlayerWindEffect, Player.Mesh, n"Hips", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);	
		PlayerWindEffectComponent.SetRenderedForPlayer(Player.OtherPlayer, false);
		PlayerWindEffectComponent.SetNiagaraVariableVec3("Strength", 0.f);
		PlayerWindEffectComponent.Deactivate();
		Reset::RegisterPersistentComponent(PlayerWindEffectComponent);

		//Fog
	/*	
		LocalFogActor = Cast<AHazeSphere>(SpawnActor(LocalFogClass.Get()));
		LocalFogActor.AttachToActor(Player);
		LocalFogActor.SetActorScale3D(1000.f);
		LocalFogActor.HazeSphereComponent.ConstructionScript_Hack();
		LocalFogActor.HazeSphereComponent.SetColor(1.f, 1.f, FLinearColor(50.f, 50.f, 50.f));
//		LocalFogActor.HazeSphereComponent.SetOpacityValue(50.f);
		LocalFogActor.HazeSphereComponent.SetRenderedForPlayer(Player.OtherPlayer, false);
	*/

		TArray<AActor> Actors;

		// Get Wind Overlapping WindVolumes
		Player.GetOverlappingActors(Actors);
		{
			for (auto Actor : Actors)
			{
				AWindWalkVolume Volume = Cast<AWindWalkVolume>(Actor);
		
				if (Volume != nullptr)
				{
					AddWindWalkVolume(Player, Volume);
				}
			}	
		}

		// Get Wind Overlapping NoWindVolumes
		Player.GetOverlappingActors(Actors);
		{
			for (auto Actor : Actors)
			{
				AWindWalkNoWindVolume Volume = Cast<AWindWalkNoWindVolume>(Actor);
		
				if (Volume != nullptr)
				{
					AddWindWalkNoWindVolume(Player, Volume);
				}
			}	
		}	

		// Get other player's magnet component
	//	OtherPlayerMagnetComp = UMagneticPlayerComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Reset::UnregisterPersistentComponent(PlayerWindEffectComponent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector TargetForce = GetWindForce();
		float TargetScale = GetWindForceScale();

		float InterpSpeed = (TargetForce.Size() > CurrentForce.Size()) ? 0.5f : 10.f;

		CurrentForce = FMath::VInterpTo(CurrentForce, TargetForce, DeltaTime, InterpSpeed);
		CurrentScale = FMath::FInterpTo(CurrentScale, TargetScale, DeltaTime, InterpSpeed);

		// Print("CurrentScale: "+ CurrentScale);
		if (LocalFogActor != nullptr)
			LocalFogActor.HazeSphereComponent.SetOpacityValue(CurrentScale * 0.0f);

		if (PlayerWindEffectComponent != nullptr)
		{
			if (PlayerWindEffectComponent.IsActive())
			{
				PlayerWindEffectComponent.SetWorldRotation(GetWindForce().Rotation());
				PlayerWindEffectComponent.SetNiagaraVariableVec3("Strength", GetWindForceScale());
			}
		}

		//	System::DrawDebugLine(Player.GetActorLocation(), Player.GetActorLocation() + GroundNormal * 300.f);

		// Don't write location if there is no active magnet
		ActiveMagnetLocation = FVector::ZeroVector;
		UHazeActivationPoint ActiveMagnet = PlayerMagnetComp.GetActivatedMagnet();
		if (ActiveMagnet != nullptr)
		{
			// If activated magnet is a player, get that player's active magnet (if one)
			if(ActiveMagnet.IsA(UMagneticPlayerAttractionComponent::StaticClass()))
			{
				// Try to make sure thet we have the other players magnet
				if (OtherPlayerMagnetComp == nullptr)
					OtherPlayerMagnetComp = UMagneticPlayerComponent::Get(Player.OtherPlayer);

				UHazeActivationPoint OtherPlayerActiveMagnet = OtherPlayerMagnetComp.GetActivatedMagnet();
				if(OtherPlayerActiveMagnet != nullptr)
					ActiveMagnetLocation = OtherPlayerActiveMagnet.GetWorldLocation();
			}
			else
			{
				ActiveMagnetLocation = ActiveMagnet.GetWorldLocation();
			}
		}
		else
		{
			ActiveMagnetLocation = FVector::ZeroVector;
		}
	}
}

void AddWindWalkVolume(AHazePlayerCharacter Player, AWindWalkVolume WindWalkVolume)
{
	UWindWalkComponent WindWalkComp = UWindWalkComponent::Get(Player);

	WindWalkComp.ActiveVolumes.Add(WindWalkVolume);
}

void RemoveWindWalkVolume(AHazePlayerCharacter Player, AWindWalkVolume WindWalkVolume)
{
	UWindWalkComponent WindWalkComp = UWindWalkComponent::Get(Player);

	WindWalkComp.ActiveVolumes.Remove(WindWalkVolume);
}

void AddWindWalkNoWindVolume(AHazePlayerCharacter Player, AWindWalkNoWindVolume WindWalkNoWindVolume)
{
	UWindWalkComponent WindWalkComp = UWindWalkComponent::Get(Player);

	WindWalkComp.ActiveNoWindVolumes.Add(WindWalkNoWindVolume);
}

void RemoveWindWalkNoWindVolume(AHazePlayerCharacter Player, AWindWalkNoWindVolume WindWalkNoWindVolume)
{
	UWindWalkComponent WindWalkComp = UWindWalkComponent::Get(Player);

	WindWalkComp.ActiveNoWindVolumes.Remove(WindWalkNoWindVolume);
}