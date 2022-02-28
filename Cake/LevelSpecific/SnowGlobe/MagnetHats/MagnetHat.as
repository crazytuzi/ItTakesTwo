import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowFolkSplineFollower;
import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHatStatics;
import Cake.LevelSpecific.SnowGlobe.SnowFolkCrowd.SnowFolkCrowdMember;

event void FOnNewAttached(AHazePlayerCharacter Player, AMagnetHat MagnetHat);
event void FOnHatDetatched(AHazePlayerCharacter Player);

enum EMagnetHatMovementState
{
	Default,
	Replaced,
	MovingToPlayer,
	Attached
}

class AMagnetHat : AHazeActor
{
	FOnNewAttached OnNewAttached;

	FOnHatDetatched OnHatDetatched;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UMagnetGenericComponent MagnetCompMay;
	default MagnetCompMay.Polarity = EMagnetPolarity::Plus_Red;
	default MagnetCompMay.ValidationType = EHazeActivationPointActivatorType::May;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMagnetGenericComponent MagnetCompCody;
	default MagnetCompCody.Polarity = EMagnetPolarity::Minus_Blue;
	default MagnetCompCody.ValidationType = EHazeActivationPointActivatorType::Cody;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 22000.f;

	UPROPERTY(Category = "Setup")
	EMagnetHatType MagnetHatType; 

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem PuffSystem;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent HatWhoosh;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent HatReturn;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent AttachToHeadAudioEvent;

	EMagnetHatMovementState MagnetHatMovementState;

	AHazePlayerCharacter TargetPlayer;

	FVector TargetLoc;

	FVector StartLoc;
	FRotator StartRot;

	float FallOffTimer;
	float DefaultFallOffTimer = 0.4f;

	float Gravity = -400.f;

	bool bIsFallingOff;
	bool bLookingForPlayer;

	UPROPERTY(Category = "Setup")
	ASnowfolkSplineFollower SnowfolkAttachTo;

	UPROPERTY(Category = "Setup")
	ASnowFolkCrowdMember CrowdSnowfolkAttachTo;

	UPROPERTY(Category = "Setup")
	UTexture WinterMaskMay;

	UPROPERTY(Category = "Setup")
	UTexture WinterMaskMay02;

	UPROPERTY(Category = "Setup")
	UTexture WinterMaskCody;

	UPROPERTY(Category = "Setup")
	UTexture WinterDefault;

	UPROPERTY(Category = "Setup")
	UMaterialInstanceDynamic MatHairMask;

	UPROPERTY(Category = "Setup")
	UMaterialInstanceDynamic MatThreadMask;

	UPROPERTY(Category = "Setup")
	UTexture MatThread;

	UPROPERTY(Category = "Setup")
	UTexture BlankMayThread;

	UPROPERTY(Category = "Setup")
	UMaterialInstanceDynamic MatHairMaskMaySpecific;

	UPROPERTY(Category = "HatTypes")
	UStaticMesh WorkerHelm;

	UPROPERTY(Category = "HatTypes")
	UStaticMesh OldLadyHat;

	UPROPERTY(Category = "HatTypes")
	UStaticMesh LighthouseKeeperHat;

	UPROPERTY(Category = "HatTypes")
	UStaticMesh FishermanHat;

	UPROPERTY(Category = "HatTypes")
	UStaticMesh PirateHat;

	UPROPERTY(Category = "HatTypes")
	UStaticMesh TopHat;

	UPROPERTY(Category = "HatTypes")
	UStaticMesh FemaleCylindricalHat;

	UPROPERTY(Category = "HatTypes")
	UStaticMesh FemaleFlatHat;

	UPROPERTY(Category = "PlayerHatSettings")
	TArray<FMagnetHatSettings> HatSettingsMay;

	UPROPERTY(Category = "PlayerHatSettings")
	TArray<FMagnetHatSettings> HatSettingsCody;

	UPROPERTY(Category = "SnowFolkHatSettings")
	FMagnetHatSettings HatSettingsCylindricalHat;

	UPROPERTY(Category = "SnowFolkHatSettings")
	FMagnetHatSettings HatSettingsFlatHat;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstanceDynamic FurballMaterial;
	
	FVector SnowFolkScale = FVector(0.6f);
	FVector OptionalAdditiveScale = FVector(0.13f);
	FVector OptionalOffset = FVector(-12.f, 0.f, 0.f);
	
	FVector MayScale = FVector(0.31f, 0.31f, 0.32f);
	FVector CodyScale = FVector(0.3f, 0.3f, 0.31f);

	FVector StartingRelativeLocation;
	FVector StartingRelativeScale;
	FRotator StartingRelativeRotation;

	FHazeAcceleratedVector AccelScale;
	
	FMagnetHatSettings HatSettings;

	bool bSnowFolkInactive;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		switch(MagnetHatType)
		{
			case EMagnetHatType::WorkerHelm: SetHatMesh(WorkerHelm); break;
			case EMagnetHatType::OldLadyHat: SetHatMesh(OldLadyHat); break;
			case EMagnetHatType::LighthouseKeeperHat: SetHatMesh(LighthouseKeeperHat); break;
			case EMagnetHatType::FishermanHat: SetHatMesh(FishermanHat); break;
			case EMagnetHatType::PirateHat: SetHatMesh(PirateHat); break;
			case EMagnetHatType::TopHat: SetHatMesh(TopHat); break;
			case EMagnetHatType::FemaleCylindricalHat: SetHatMesh(FemaleCylindricalHat); break;
			case EMagnetHatType::FemaleFlatHat: SetHatMesh(FemaleFlatHat); break;
		}
				
		if (SnowfolkAttachTo == nullptr && CrowdSnowfolkAttachTo == nullptr)
		{
			AccelScale.SnapTo(MayScale);
			SetActorScale3D(MayScale);
		}
		else if (SnowfolkAttachTo != nullptr)
		{
			SnowfolkAttachTo.OnSnowFolkDisabled.AddUFunction(this, n"HideHat");
			SnowfolkAttachTo.OnSnowfolkEnabled.AddUFunction(this, n"ShowHat");
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagnetCompMay.OnActivatedBy.AddUFunction(this, n"OnMagnetActivated");
		MagnetCompCody.OnActivatedBy.AddUFunction(this, n"OnMagnetActivated");

		AddCapability(n"MagnetHatMovementCapability");
		AddCapability(n"MagnetHatAttachCapability");

		StartingRelativeLocation = MeshComp.RelativeLocation;
		StartingRelativeScale = MeshComp.RelativeScale3D;
		StartingRelativeRotation = MeshComp.RelativeRotation;

		StartLoc = ActorLocation;
		StartRot = ActorRotation;

		if (SnowfolkAttachTo != nullptr || CrowdSnowfolkAttachTo != nullptr)
			AttachToSnowfolkHead();
		
		MagnetCompMay.ChangeValidActivator(EHazeActivationPointActivatorType::May);
		MagnetCompCody.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);
	}

	UFUNCTION()
	void SetHatMesh(UStaticMesh ChosenMesh = nullptr, UMaterial ChosenMaterial = nullptr)
	{
		if (ChosenMesh != nullptr)
			MeshComp.SetStaticMesh(ChosenMesh);
		
		if (ChosenMaterial != nullptr)
			MeshComp.SetMaterial(0, ChosenMaterial);
	}

	UFUNCTION()
	void OnMagnetActivated(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		MagnetCompMay.bIsDisabled = true;

		// if (Player.HasControl() != HasControl())
		// 	NetChangeControlSideAndSetControllingPlayer(Player);

		TargetPlayer = Player;
		MagnetHatMovementState = EMagnetHatMovementState::MovingToPlayer;
		Player.PlayerHazeAkComp.HazePostEvent(HatWhoosh); 
	}

	UFUNCTION(NetFunction)
	void NetChangeControlSideAndSetControllingPlayer(AHazePlayerCharacter Player)
	{
		SetControlSide(Player);
	}
	
	UFUNCTION()
	void InitiateNewHatSettings()
	{
		if (TargetPlayer != nullptr)
		{
			if (TargetPlayer.IsMay())
			{
				for (FMagnetHatSettings Settings : HatSettingsMay)
				{
					if (Settings.Type == MagnetHatType)
						HatSettings = Settings;
				}	
			}
			else
			{
				for (FMagnetHatSettings Settings : HatSettingsCody)
				{
					if (Settings.Type == MagnetHatType)
						HatSettings = Settings;
				}	
			}
		}
	}

	UFUNCTION()
	void SetHatScaleAndMaterial(AHazePlayerCharacter AttachedPlayer)
	{
		MeshComp.SetRelativeLocation(StartingRelativeLocation + HatSettings.OffsetLoc);
		MeshComp.SetRelativeScale3D(StartingRelativeScale + HatSettings.AddedScale);
		MeshComp.SetRelativeRotation(StartingRelativeRotation + HatSettings.OffsetRot);

		if (AttachedPlayer == Game::May)
		{
			AccelScale.SnapTo(MayScale);
			SetActorScale3D(MayScale);
			MatHairMask = AttachedPlayer.Mesh.CreateDynamicMaterialInstance(7);	
			MatThreadMask = AttachedPlayer.Mesh.CreateDynamicMaterialInstance(10);
			MatHairMaskMaySpecific = AttachedPlayer.Mesh.CreateDynamicMaterialInstance(3);
			MatHairMask.SetTextureParameterValue(n"C5", WinterMaskMay);
			MatThreadMask.SetTextureParameterValue(n"C5", BlankMayThread);
			MatHairMaskMaySpecific.SetTextureParameterValue(n"C5", WinterMaskMay02);
		}
		else
		{
			AccelScale.SnapTo(CodyScale);
			SetActorScale3D(CodyScale);
			MatHairMask = AttachedPlayer.Mesh.CreateDynamicMaterialInstance(3);
			MatHairMask.SetTextureParameterValue(n"C5", WinterMaskCody);
			FurballMaterial = AttachedPlayer.Mesh.CreateDynamicMaterialInstance(2);
			FurballMaterial.SetScalarParameterValue(n"Opacity", 0.f);
		}
	}

	UFUNCTION()
	void AttachToSnowfolkHead()
	{
		if (MagnetHatType == EMagnetHatType::WorkerHelm)
		{
			AccelScale.SnapTo(SnowFolkScale);
			SetActorScale3D(SnowFolkScale);
			MeshComp.SetRelativeLocation(StartingRelativeLocation);
			MeshComp.SetRelativeScale3D(StartingRelativeScale);
			MeshComp.SetRelativeRotation(StartingRelativeRotation);
		}
		else if (MagnetHatType == EMagnetHatType::FemaleCylindricalHat)
		{
			AccelScale.SnapTo(SnowFolkScale);
			SetActorScale3D(SnowFolkScale);
			MeshComp.SetRelativeLocation(StartingRelativeLocation + HatSettingsCylindricalHat.OffsetLoc);
			MeshComp.SetRelativeScale3D(StartingRelativeScale);
			MeshComp.SetRelativeRotation(StartingRelativeRotation + HatSettingsCylindricalHat.OffsetRot);
		}
		else if (MagnetHatType == EMagnetHatType::FemaleFlatHat)
		{
			AccelScale.SnapTo(SnowFolkScale);
			SetActorScale3D(SnowFolkScale);
			MeshComp.SetRelativeLocation(StartingRelativeLocation + HatSettingsFlatHat.OffsetLoc);
			MeshComp.SetRelativeScale3D(StartingRelativeScale);
			MeshComp.SetRelativeRotation(StartingRelativeRotation + HatSettingsFlatHat.OffsetRot);		
		}
		else
		{
			AccelScale.SnapTo(SnowFolkScale);
			SetActorScale3D(SnowFolkScale);	
			MeshComp.SetRelativeScale3D(StartingRelativeScale + OptionalAdditiveScale);		
			MeshComp.SetRelativeLocation(StartingRelativeLocation + OptionalOffset);
			MeshComp.SetRelativeRotation(StartingRelativeRotation);
		}
		
		if (SnowfolkAttachTo != nullptr)
			AttachToComponent(SnowfolkAttachTo.SkeletalMeshComponent, n"HeadSocket");

		if (CrowdSnowfolkAttachTo != nullptr)
			AttachToComponent(CrowdSnowfolkAttachTo.SkeletalMeshComponent, n"HeadSocket");
	}

	UFUNCTION()
	void HideHat()
	{
		MeshComp.SetHiddenInGame(true);
		MagnetCompMay.bIsDisabled = true;
	}

	UFUNCTION()
	void ShowHat()
	{
		MeshComp.SetHiddenInGame(false);
		MagnetCompMay.bIsDisabled = false;
	}

	UFUNCTION()
	void RemoveFromHead(AHazePlayerCharacter Player = nullptr)
	{
		MeshComp.SetRelativeLocation(StartingRelativeLocation);
		MeshComp.SetRelativeScale3D(StartingRelativeScale);

		if (Player != nullptr)
		{
			MatHairMask.SetTextureParameterValue(n"C5", WinterDefault);

			if (Player == Game::Cody)
				FurballMaterial.SetScalarParameterValue(n"Opacity", 1.f);
			else
				MatThreadMask.SetTextureParameterValue(n"C5", MatThread);
		}
	}

	UFUNCTION()
	void SendToOriginalPosition()
	{
		bIsFallingOff = false;

		if (TargetPlayer != nullptr)
			TargetPlayer.PlayerHazeAkComp.HazePostEvent(HatReturn);
		
		TargetPlayer = nullptr;

		MeshComp.SetRelativeLocation(StartingRelativeLocation);
		MeshComp.SetRelativeScale3D(StartingRelativeScale);
				
		if (PuffSystem != nullptr)
			Niagara::SpawnSystemAtLocation(PuffSystem, ActorLocation, ActorRotation);

		if (SnowfolkAttachTo != nullptr || CrowdSnowfolkAttachTo != nullptr)
		{
			AttachToSnowfolkHead();
		}
		else
		{
			SetActorLocationAndRotation(StartLoc, StartRot);

			AccelScale.SnapTo(MayScale);
			SetActorScale3D(MayScale);
		}

		Niagara::SpawnSystemAtLocation(PuffSystem, ActorLocation, ActorRotation);
		AkComp.HazePostEvent(HatReturn);
	}

	void FallOffHead()
	{
		bIsFallingOff = true;
		FallOffTimer = DefaultFallOffTimer;
	}
}