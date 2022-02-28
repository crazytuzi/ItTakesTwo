import Vino.Interactions.OneShotInteraction;
import Vino.Interactions.AnimNotify_Interaction;

event void FButtonPressed();

UCLASS(Abstract, HideCategories = "Cooking")
class AOneShotButton : AOneShotInteraction
{
    UPROPERTY(DefaultComponent)
    UStaticMeshComponent ButtonBase;
    default ButtonBase.SetRelativeLocation(FVector(215.f, 0.f, 0.f));
    default ButtonBase.SetRelativeRotation(FRotator(0.f, 180.f, 0.f));
    default ButtonBase.LightmapType = ELightmapType::ForceVolumetric;
    default ButtonBase.RemoveTag(ComponentTags::LedgeGrabbable);

    UPROPERTY(DefaultComponent, Attach = RootComponent)
    UHazeSkeletalMeshComponentBase ButtonRoot;
    default ButtonRoot.SetRelativeLocation(FVector(95.f, 0.f, 120.f));
	default ButtonRoot.SetRelativeRotation(FRotator(0.f, 180.f, 0.f));

    UPROPERTY(DefaultComponent, Attach = ButtonRoot)
    UStaticMeshComponent Button;
    default Button.LightmapType = ELightmapType::ForceVolumetric;
    default Button.RemoveTag(ComponentTags::LedgeGrabbable);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 10000.f;

    default FocusShapeTransform = FTransform(FRotator::ZeroRotator, FVector::ZeroVector, FVector(1.5f, 1.5f, 1.5f));
    default FocusShapeSettings.Type = EHazeShapeType::Sphere;
    
    UPROPERTY(Category = "ButtonProperties")
    bool bSingleUse = false;

	UPROPERTY(Category = "ButtonProperties")
	UAnimSequence CodyButtonAnim;

	UPROPERTY(Category = "ButtonProperties")
	UAnimSequence MayButtonAnim;

	UPROPERTY(Category = "ButtonProperties")
	UAnimSequence ResetAnimation;

	UPROPERTY(Category = "ButtonProperties")
	float InteractionDelayAfterReset = 0.f;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent OnButtonActivatedAudioEvent;
	
	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent OnButtonPressedAudioEvent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent OnButtonResetAudioEvent;

	UPROPERTY()
	FButtonPressed OnButtonPressed;

	FHazeAnimNotifyDelegate AnimNotifyDelegate;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		Button.SetCullDistance(Editor::GetDefaultCullingDistance(Button) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnOneShotActivated.AddUFunction(this, n"InteractionActivated");
	}

	UFUNCTION(NotBlueprintCallable)
	void InteractionActivated(AHazePlayerCharacter Player, AOneShotInteraction Interaction)
	{
		DisableInteraction(n"Used");
		PlayButtonAnimation(Player);
		if(OnButtonActivatedAudioEvent != nullptr)
			Player.PlayerHazeAkComp.HazePostEvent(OnButtonActivatedAudioEvent);
		
		AnimNotifyDelegate.BindUFunction(this, n"ButtonPressed");
		Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);
	}

    UFUNCTION(NotBlueprintCallable)
    void PlayButtonAnimation(AHazePlayerCharacter Player)
    {
        FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Player.IsCody() ? CodyButtonAnim : MayButtonAnim;

        FHazeAnimationDelegate OnButtonAnimationFinished;
        OnButtonAnimationFinished.BindUFunction(this, n"ButtonAnimationFinished");

        ButtonRoot.PlaySlotAnimation(FHazeAnimationDelegate(), OnButtonAnimationFinished, AnimParams);

		UAnimSequence Anim = AnimParams.Animation;
    }

	UFUNCTION(NotBlueprintCallable)
	void ButtonPressed(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);
		OnButtonPressed.Broadcast();

		if(OnButtonPressedAudioEvent != nullptr)
			UHazeAkComponent::HazePostEventFireForget(OnButtonPressedAudioEvent, GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void ButtonAnimationFinished()
	{
		if (bSingleUse)
			return;
	
		ResetButton();
	}

	UFUNCTION()
	void ResetButton()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = ResetAnimation;

		ButtonRoot.PlaySlotAnimation(AnimParams);
		if(OnButtonResetAudioEvent != nullptr)
			UHazeAkComponent::HazePostEventFireForget(OnButtonResetAudioEvent, GetActorTransform());

		if (InteractionDelayAfterReset <= 0.f)
			EnableInteraction(n"Used");
		else

			System::SetTimer(this, n"EnableInteractionAfterDelay", InteractionDelayAfterReset, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnableInteractionAfterDelay()
	{
		EnableInteraction(n"Used");
	}

    UFUNCTION()
    void SetVisualOffset(FTransform Offset)
    {
        FHazeTriggerVisualSettings NewVisualSettings;
        NewVisualSettings.VisualOffset = FTransform(Offset);
        TriggerComponent.SetVisualSettings(NewVisualSettings);
    }
}