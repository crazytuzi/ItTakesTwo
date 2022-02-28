import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;
import Vino.Movement.Components.MovementComponent;

class JumpingFrogAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	AJumpingFrog Frog;
	UHazeAkComponent FrogHazeAkComp;
	UHazeFrogMovementComponent MoveComp;

	float LastFrogVelocityNormalized;
	float FrogIsMounted;
	float LastFrogChargeAmountNormalized;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Mount;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Dismount;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BigJump;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BigLand;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent SmallJump;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent SmallLand;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RespawnMay;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RespawnCody;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent MountVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent DismountVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent BigJumpVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent BigLandVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent SmallJumpVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent ChargeStartVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent ChargeFullVocal;

	UPROPERTY(Category = "Vocal")
	UAkAudioEvent DeathVocal;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        FrogHazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		Frog = Cast<AJumpingFrog>(Owner);
		MoveComp = UHazeFrogMovementComponent::GetOrCreate(Owner);
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
		if(Frog.MountedPlayer != nullptr)
			HazeAudio::SetPlayerPanning(FrogHazeAkComp, Frog.MountedPlayer);		
		
		if (ConsumeAction(n"AudioFrogMount") == EActionStateStatus::Active)
		{
			FrogHazeAkComp.HazePostEvent(Mount);
			FrogHazeAkComp.HazePostEvent(MountVocal);
			//PrintScaled("Mount", 2.f, FLinearColor::Black, 2.f);
			FrogIsMounted = 1.f;
		}
		
		if (ConsumeAction(n"AudioFrogDismount") == EActionStateStatus::Active)
		{
			FrogHazeAkComp.HazePostEvent(Dismount);
			//PrintScaled("Dismount", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioFrogBigJump") == EActionStateStatus::Active)
		{
			FrogHazeAkComp.HazePostEvent(BigJump);
			FrogHazeAkComp.HazePostEvent(BigJumpVocal);
			//PrintScaled("BigJump", 2.f, FLinearColor::Black, 2.f);
		}
		
		if (ConsumeAction(n"AudioFrogBigLand") == EActionStateStatus::Active)
		{
			FrogHazeAkComp.HazePostEvent(BigLand);
			FrogHazeAkComp.HazePostEvent(BigLandVocal);
			//PrintScaled("BigLand", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioFrogSmallJump") == EActionStateStatus::Active)
		{
			FrogHazeAkComp.HazePostEvent(SmallJump);
			FrogHazeAkComp.HazePostEvent(SmallJumpVocal);
			//PrintScaled("SmallJump", 2.f, FLinearColor::Black, 2.f);
		}
		
		if (ConsumeAction(n"AudioFrogSmallLand") == EActionStateStatus::Active)
		{
			FrogHazeAkComp.HazePostEvent(SmallLand);
			//PrintScaled("SmallLand", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioFrogDeath") == EActionStateStatus::Active)
		{
			FrogHazeAkComp.HazePostEvent(DeathVocal);
			//PrintScaled("Death", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioFrogRespawn") == EActionStateStatus::Active)
		{
			
			if(Frog.bIsMaysFrog)
				FrogHazeAkComp.HazePostEvent(RespawnMay);
			else
				FrogHazeAkComp.HazePostEvent(RespawnCody);
			
		}

		//float FrogVelocity = GetAttributeValue(n"AudioFrogVelocity");

		float FrogVelocity = MoveComp.GetActualVelocity().Size();

		float FrogVelocityNormalized = HazeAudio::NormalizeRTPC01(FrogVelocity, 0.f, 3500.f);

		FrogHazeAkComp.SetRTPCValue("Rtpc_Vehicles_Frog_Velocity", FrogVelocityNormalized, 0.f);

		float FrogChargeAmount = GetAttributeValue(n"AudioFrogChargeTime");

		float FrogChargeAmountNormalized = HazeAudio::NormalizeRTPC01(FrogChargeAmount, 0.f, 0.8f);

		FrogHazeAkComp.SetRTPCValue("Rtpc_Vehicles_Frog_ChargeAmount", FrogChargeAmountNormalized, 0.f);


		float FrogDistanceToGround = Frog.DistanceToGround;

		float FrogDistanceToGroundNormalized = HazeAudio::NormalizeRTPC01(FrogDistanceToGround, 0.f, 1000.f);

		FrogHazeAkComp.SetRTPCValue("Rtpc_Vehicles_Frog_DistanceToGround", FrogDistanceToGroundNormalized, 0.f);


		float FrogVerticalDirection = Frog.VerticalTravelDirection;

		FrogHazeAkComp.SetRTPCValue("Rtpc_Vehicles_Frog_VerticalDirection", FrogVerticalDirection, 0.f);

		if (ConsumeAction(n"AudioFrogChargeStart") == EActionStateStatus::Active)
		{
			FrogHazeAkComp.HazePostEvent(ChargeStartVocal);
			//PrintScaled("ChargeStart", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioFrogChargeStop") == EActionStateStatus::Active)
		{
			FrogHazeAkComp.HazePostEvent(ChargeFullVocal);
			//PrintScaled("ChargeStart", 2.f, FLinearColor::Black, 2.f);
		}


		if (FrogIsMounted == 1)
		{
			//Print("Frog VeloNorm: " + FrogVelocityNormalized);
			//Print("Frog ChargeAmountNorm: " + FrogChargeAmountNormalized);
			//Print("Frog DistanceToGroundNorm: " + FrogDistanceToGroundNormalized);
			//Print("Frog VerticalDirection: " + FrogVerticalDirection);
		}
	}

}