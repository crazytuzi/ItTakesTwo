import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;

class WallWalkingAnimalAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	AWallWalkingAnimal SpiderOwner;
	UHazeAkComponent SpiderHazeAkComp;
	UWallWalkingAnimalComponent PlayerComp;

	float LastSpiderVelocityNormalized;
	FString LastMaterialSwitch = "";

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Mount;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Dismount;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StandUp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StandDown;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Jump;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Land;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Death;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WebShoot;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WebPickup;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RespawnMay;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RespawnCody;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent StartWalkingVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent StopWalkingVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent MountVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent DismountVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent StandUpVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent StandDownVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent JumpVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent LandVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent DeathVocal;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        SpiderHazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		SpiderOwner = Cast<AWallWalkingAnimal>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(SpiderOwner.Player != nullptr && PlayerComp == nullptr)
		{
			PlayerComp = UWallWalkingAnimalComponent::Get(SpiderOwner.Player);
			HazeAudio::SetPlayerPanning(SpiderHazeAkComp, SpiderOwner.Player);		
		}

		if (ConsumeAction(n"AudioSpiderMount") == EActionStateStatus::Active)
		{
			SpiderHazeAkComp.HazePostEvent(Mount);
			SpiderHazeAkComp.HazePostEvent(MountVocal);
			//PrintScaled("Mount", 2.f, FLinearColor::Black, 2.f);
		}
		
		if (ConsumeAction(n"AudioSpiderDismount") == EActionStateStatus::Active)
		{
			SpiderHazeAkComp.HazePostEvent(Dismount);
			//PrintScaled("Dismount", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioSpiderStandUp") == EActionStateStatus::Active)
		{
			SpiderHazeAkComp.HazePostEvent(StandUp);
			SpiderHazeAkComp.HazePostEvent(StandUpVocal);
			//PrintScaled("StandUp", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioSpiderStandDown") == EActionStateStatus::Active)
		{
			SpiderHazeAkComp.HazePostEvent(StandDown);
			//PrintScaled("StandDown", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioSpiderJump") == EActionStateStatus::Active)
		{
			SpiderHazeAkComp.HazePostEvent(Jump);
			SpiderHazeAkComp.HazePostEvent(JumpVocal);
			SpiderHazeAkComp.HazePostEvent(WebShoot);
			//PrintScaled("Jump", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioSpiderLand") == EActionStateStatus::Active)
		{
			SpiderHazeAkComp.HazePostEvent(Land);
			SpiderHazeAkComp.HazePostEvent(LandVocal);
			SpiderHazeAkComp.HazePostEvent(WebPickup);
			//PrintScaled("Land", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioSpiderDeath") == EActionStateStatus::Active)
		{
			SpiderHazeAkComp.HazePostEvent(Death);
			SpiderHazeAkComp.HazePostEvent(DeathVocal);
			//PrintScaled("Death", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioSpiderSlideOffSap") == EActionStateStatus::Active)
		{
			SpiderHazeAkComp.HazePostEvent(Death);
			SpiderHazeAkComp.HazePostEvent(DeathVocal);
			//PrintScaled("Death", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioSpiderRespawn") == EActionStateStatus::Active)
		{
			if(SpiderOwner.Player.IsMay())
				SpiderHazeAkComp.HazePostEvent(RespawnMay);
			else
				SpiderHazeAkComp.HazePostEvent(RespawnCody);
		}

		float SpiderVelocity = GetAttributeValue(n"AudioSpiderVelocity");

		float SpiderVelocityNormalized = HazeAudio::NormalizeRTPC01(SpiderVelocity, 0.f, 2000.f);

		SpiderHazeAkComp.SetRTPCValue("Rtpc_Vehicles_Spider_Velocity", SpiderVelocityNormalized, 0.f);

		if (SpiderVelocityNormalized == 0.f)
		{
			if (SpiderVelocityNormalized != LastSpiderVelocityNormalized)
			{
				SpiderHazeAkComp.HazePostEvent(StopWalkingVocal);
				//PrintScaled("StopWalk", 2.f, FLinearColor::Black, 2.f);
				LastSpiderVelocityNormalized = SpiderVelocityNormalized;
			}
		}

		if (FMath::IsNearlyEqual(SpiderVelocityNormalized, 1.f))
		{
			if (SpiderVelocityNormalized != LastSpiderVelocityNormalized)
			{
				SpiderHazeAkComp.HazePostEvent(StartWalkingVocal);
				//PrintScaled("StartWalk", 2.f, FLinearColor::Black, 2.f);
				LastSpiderVelocityNormalized = SpiderVelocityNormalized;
			}
		}

		//Print("VeloNorm" + SpiderVelocityNormalized);

		float SpiderIsInPurpleSap = GetAttributeValue(n"AudioSpiderIsInPurpleSap");

		SpiderHazeAkComp.SetRTPCValue("Rtpc_Vehicles_Spider_IsInPurpleSap", SpiderIsInPurpleSap, 0.f);

		//Print("IsInPurpleSap" + SpiderIsInPurpleSap);

		UObject RawAsset;
		if(ConsumeAttribute(n"AudioSpiderContactSurface", RawAsset))
		{			
			UPhysicalMaterialAudio AudioMat = Cast<UPhysicalMaterialAudio>(RawAsset);
			if(AudioMat == nullptr)
				return;

			TArray<FString> MaterialData;
			AudioMat.GetMaterialSwitch(MaterialData);

			if(MaterialData[1] != LastMaterialSwitch)
			{
				SpiderHazeAkComp.SetSwitch(MaterialData[0], MaterialData[1]);
				LastMaterialSwitch = MaterialData[1];
			}
		}
	}
}