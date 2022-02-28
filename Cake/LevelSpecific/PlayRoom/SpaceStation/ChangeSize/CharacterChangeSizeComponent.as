import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundStatics;
import Vino.PlayerHealth.PlayerHealthSettings;
import Vino.Movement.MovementSettings;
import Peanuts.Audio.AudioStatics;
import Vino.PlayerHealth.PlayerRespawnComponent;

event void FOnCharacterChangedSize(FChangeSizeEventTempFix NewSize);

class UCharacterChangeSizeCallbackComponent : UActorComponent
{
	UPROPERTY()
	FOnCharacterChangedSize OnCharacterChangedSize;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UCharacterChangeSizeCallbackListComponent ListComp = UCharacterChangeSizeCallbackListComponent::GetOrCreate(Game::GetCody());
		if (ListComp != nullptr)
			ListComp.AddCallbackComponentToList(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		UCharacterChangeSizeCallbackListComponent ListComp = UCharacterChangeSizeCallbackListComponent::Get(Game::GetCody());
		if (ListComp != nullptr)
			ListComp.RemoveCallbackComponentFromList(this);
	}

	void CharacterChangedSize(FChangeSizeEventTempFix NewSize)
	{
		OnCharacterChangedSize.Broadcast(NewSize);
		BP_CharacterChangedSize(NewSize);
	}

	UFUNCTION(BlueprintEvent)
	void BP_CharacterChangedSize(FChangeSizeEventTempFix NewSize) {}

}

class UCharacterChangeSizeCallbackListComponent : UActorComponent
{
	TArray<UCharacterChangeSizeCallbackComponent> CallbackComps;

	void SizeChanged(FChangeSizeEventTempFix NewSize)
	{
		for (UCharacterChangeSizeCallbackComponent CallbackComp : CallbackComps)
		{
			CallbackComp.CharacterChangedSize(NewSize);
		}
	}

	void AddCallbackComponentToList(UCharacterChangeSizeCallbackComponent Comp)
	{
		if (CallbackComps.Num() == 0)
			Reset::RegisterPersistentComponent(this);

		CallbackComps.Add(Comp);
	}

	void RemoveCallbackComponentFromList(UCharacterChangeSizeCallbackComponent Comp)
	{
		CallbackComps.Remove(Comp);

		if (CallbackComps.Num() == 0)
			Reset::UnregisterPersistentComponent(this);
	}
}

UCLASS(Abstract, HideCategories = "ComponentTick Activation Cooking ComponentReplication Variable Tags AssetUserData Collision")
class UCharacterChangeSizeComponent : UActorComponent
{
    UPROPERTY()
    ECharacterSize CurrentSize = ECharacterSize::Medium;

    UPROPERTY()
    FOnCharacterChangedSize OnCharacterChangedSize;

	UPROPERTY(Category = "Small")
	UHazeCameraSpringArmSettingsDataAsset SmallCameraSettings;

	UPROPERTY(Category = "Large")
	UHazeCameraSpringArmSettingsDataAsset LargeCameraSettings;

	UPROPERTY(Category = "Small")
	TSubclassOf<UCameraShakeBase> SmallGroundPoundCameraShake;

	UPROPERTY()
	FChangeSizeCameraShake CameraShakes;

	UPROPERTY(Category = "Small")
	UHazeCapabilitySheet SmallSheet;

	UPROPERTY(Category = "Large")
	UHazeCapabilitySheet LargeSheet;

	UPROPERTY(Category = "Large")
	UHazeLocomotionStateMachineAsset LargeStateMachineAsset;

	UPROPERTY(Category = "Small")
	UPlayerHealthSettings SmallHealthSettings;

	UPROPERTY(Category = "Large")
	UPlayerHealthSettings LargeHealthSettings;

	UPROPERTY(Category = "Large")
	UMovementSettings LargeMovementSettings;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LargeToMediumEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MediumToLargeEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MediumToSmallEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SmallToMediumEvent;

	UPROPERTY(Category = "Obstructed")
	UAnimSequence ObstructedAnimation;

	UPROPERTY(Category = "Obstructed")
	UForceFeedbackEffect ObstructedForceFeedback;

	UPROPERTY(Category = "Obstructed")
	UNiagaraSystem SmallToMediumObstructedEffect;

	UPROPERTY(Category = "Obstructed")
	UNiagaraSystem MediumToLargeObstructedEffect;

	UPROPERTY(Category = "Small")
	UNiagaraSystem SmallRespawnEffect;

	UPROPERTY(Category = "Large")
	UNiagaraSystem LargeRespawnEffect;

	bool bChangingSize = false;

    float GroundPoundHeightSizeModifier;
    FCharacterSizeValues GroundPoundHeightSizeModifierValues;
    default GroundPoundHeightSizeModifierValues.Small = 0.5f;
    default GroundPoundHeightSizeModifierValues.Medium = 1.f;
    default GroundPoundHeightSizeModifierValues.Large = 2.f;

    float JumpHeightSizeModifer;
    FCharacterSizeValues JumpHeightSizeModifierValues;
    default JumpHeightSizeModifierValues.Small = 0.1f;
    default JumpHeightSizeModifierValues.Medium = 1.f;
    default JumpHeightSizeModifierValues.Large = 2.f;

	void SetSize(ECharacterSize Size)
	{
		EChangeSizeTransitionTempFix Transition;
		Transition.Transition = EChangeSizeTransition::MediumToLarge;

		if (CurrentSize == ECharacterSize::Medium && Size == ECharacterSize::Small)
			Transition.Transition = EChangeSizeTransition::MediumToSmall;
		else if (CurrentSize == ECharacterSize::Large && Size == ECharacterSize::Medium)
			Transition.Transition = EChangeSizeTransition::LargeToMedium;
		else if (CurrentSize == ECharacterSize::Small && Size== ECharacterSize::Medium)
			Transition.Transition = EChangeSizeTransition::SmallToMedium;

		BP_SizeChanged(Transition);
		CurrentSize = Size;
		SizeChanged(CurrentSize);
	}

    void SizeChanged(ECharacterSize NewSize)
    {
        CurrentSize = NewSize;

		UCharacterChangeSizeCallbackListComponent CallbackListComp = UCharacterChangeSizeCallbackListComponent::GetOrCreate(Owner);
		if (CallbackListComp != nullptr)
		{
			FChangeSizeEventTempFix TempFix;
        	TempFix.NewSize = NewSize;
			CallbackListComp.SizeChanged(TempFix);
		}

		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Cody_SpaceStation_Size", CurrentSize, 0.0f);		
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Cody_SpaceStation_Size", 1, 0.0f);

		ResetPlayerGroundPoundLandCameraImpulse(Game::GetCody());
	}

	UFUNCTION(BlueprintEvent)
	void BP_SizeChanged(EChangeSizeTransitionTempFix Transition) {}
}

enum EChangeSizeTransition
{
	MediumToLarge,
	MediumToSmall,
	LargeToMedium,
	SmallToMedium
}

struct EChangeSizeTransitionTempFix
{
	UPROPERTY()
	EChangeSizeTransition Transition;
}

struct FChangeSizeCameraShake
{
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SmallToMedium;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> MediumToLarge;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LargeToMedium;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> MediumToSmall;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SmallObstructed;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> MediumObstructed;
}