import Peanuts.Audio.AudioStatics;

class SickleAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	UPlayerHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Equip;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Unequip;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Impact;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HazeAkComp = UPlayerHazeAkComponent::GetOrCreate(Owner);
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

		if (ConsumeAction(n"AudioSickleEquip") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(Equip);
			//PrintScaled("SickleEquip", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioSickleUnequip") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(Unequip);
			//PrintScaled("SickleUnequip", 2.f, FLinearColor::Black, 2.f);
		}

		float SickleDamageAmount = GetAttributeValue(n"AudioSickleDamageAmount");

		if (ConsumeAction(n"AudioSickleImpact") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(Impact);
			//PrintScaled("SickleImpact", 0.5f, FLinearColor::Black, 2.f);
			//Print("SickleDamageAmount" + SickleDamageAmount, 0.f);
		}

	}
}