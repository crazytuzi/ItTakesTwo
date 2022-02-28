import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;
import Peanuts.Audio.AudioStatics;

class UCastleUltimateCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Castle");
    default CapabilityTags.Add(n"Ability");
    default CapabilityTags.Add(n"CastleAbility");

	default TickGroup = ECapabilityTickGroups::ActionMovement;	

    default CapabilityDebugCategory = n"Castle";

    UPROPERTY(NotEditable)
    AHazePlayerCharacter OwningPlayer;
    UPROPERTY(NotEditable)
    UCastleComponent CastleComponent;

	UHazeAkComponent CastleAkComponent;
	UPROPERTY()
	UAkAudioEvent FullUltimateAudioEvent;
	UPROPERTY()
	UNiagaraSystem UltimateReadyEffect;
	UPROPERTY()
	TSubclassOf<UHazeUserWidget> UltimateButtonPrompt;

	private UNiagaraComponent EffectComp;
	private UHazeUserWidget Prompt;
	private bool bSoundPlayed = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		
		CastleComponent = UCastleComponent::Get(Owner);
		CastleAkComponent = UHazeAkComponent::Get(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsPlayerDead(OwningPlayer))
			return EHazeNetworkActivation::DontActivate;
		if (CastleComponent.UltimateCharge >= CastleComponent.UltimateChargeMax)
        	return EHazeNetworkActivation::ActivateUsingCrumb;
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsPlayerDead(OwningPlayer))
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (CastleComponent.UltimateCharge < CastleComponent.UltimateChargeMax)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		if (!bSoundPlayed)
		{
			PlayAudioEventFromComponent(FullUltimateAudioEvent);
			bSoundPlayed = true;
		}

		if (UltimateReadyEffect != nullptr)
		{
			EffectComp = Niagara::SpawnSystemAttached(
				UltimateReadyEffect,
				OwningPlayer.RootComponent,
				NAME_None, FVector(0.f, 0.f, 80.f), FRotator(),
				EAttachLocation::KeepRelativeOffset, false);
		}

		if (UltimateButtonPrompt.IsValid())
		{
			Prompt = OwningPlayer.AddWidget(UltimateButtonPrompt);
			Prompt.AttachWidgetToComponent(OwningPlayer.Mesh);
			Prompt.SetWidgetRelativeAttachOffset(FVector(0.f, 0.f, 176.f));
			Prompt.SetWidgetShowInFullscreen(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (EffectComp != nullptr)
		{
			EffectComp.DestroyComponent(EffectComp);
			EffectComp = nullptr;
		}

		if (Prompt != nullptr)
		{
			OwningPlayer.RemoveWidget(Prompt);
			Prompt = nullptr;
		}
	} 

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{	
		if (CastleComponent.UltimateCharge < CastleComponent.UltimateChargeMax)
			bSoundPlayed = false;
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
	}	

	void PlayAudioEventFromComponent(UAkAudioEvent AudioEvent)
	{
		if (AudioEvent != nullptr)
			CastleAkComponent.HazePostEvent(AudioEvent);
	}
}