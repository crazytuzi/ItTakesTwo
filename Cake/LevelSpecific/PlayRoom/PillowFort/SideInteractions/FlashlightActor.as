import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;
import Cake.LevelSpecific.PlayRoom.VOBanks.PillowFortVOBank;

class AFlashlightActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotlightComp;
	default SpotlightComp.SetCastShadows(false);
	default SpotlightComp.Mobility = EComponentMobility::Movable;
	default SpotlightComp.SetVisibility(false);
	default SpotlightComp.SetActive(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UForceFeedbackEffect OnInteractedForceFeedback;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(EditDefaultsOnly ,Category = "Setup")
	UPillowFortVOBank PillowfortVOBank;

	UPROPERTY(EditDefaultsOnly ,Category = "Setup")
	UAnimSequence CodyAnim;
	UPROPERTY(EditDefaultsOnly ,Category = "Setup")
	UAnimSequence MayAnim;

	UPROPERTY(EditDefaultsOnly ,Category = "Settings")
	bool AlignLocation = false;

	UPROPERTY(EditDefaultsOnly ,Category = "Settings")
	bool AlignRotation = false;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	int LightMaterialIndex = 0;

	UPROPERTY(EditDefaultsOnly ,Category = "Setup")
	UMaterialInstance ActiveMaterial;
	UPROPERTY(EditDefaultsOnly ,Category = "Setup")
	UMaterialInstance DeactivatedMaterial;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FHazeTimeLike ButtonTimeLike;

	UPROPERTY(EditDefaultsOnly, Category = "Audio Events")
	UAkAudioEvent PlayButtonAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio Events")
	UAkAudioEvent PlayLightOnAudioEvent;

	//Set to match state of actor in level (If turned on set to true)
	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bIsActive = false;

	bool bHasPlayedMayVOEvent = false;
	bool bHasPlayedCodyVOEvent = false;
	
	AHazePlayerCharacter InteractingPlayer;
	FHazeAnimNotifyDelegate AnimNotifyDelegate;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		InteractionComp.OnActivated.AddUFunction(this, n"OnInteracted");
	}
	
	UFUNCTION()
	void OnInteracted(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(n"InUse");

		InteractingPlayer = Player;
		
		Player.CleanupCurrentMovementTrail();

		if(AlignLocation)
		{
			FTransform AlignTransform;

			if(Player.IsCody())
				Animation::GetAnimAlignBoneTransform(AlignTransform, CodyAnim, 0.f);
			else
				Animation::GetAnimAlignBoneTransform(AlignTransform, MayAnim, 0.f);

			if(Player.IsCody())
				Animation::GetAnimAlignBoneTransform(AlignTransform, CodyAnim, 0.f);
			else
				Animation::GetAnimAlignBoneTransform(AlignTransform, MayAnim, 0.f);

			float AlignOffset;
			AlignOffset = AlignTransform.Location.X;
			FVector AlignPosition = Player.ActorLocation - Root.WorldLocation;
			AlignPosition = AlignPosition.GetSafeNormal();
			AlignPosition *= AlignOffset;
			AlignPosition += Root.WorldLocation;

			Player.SetActorLocation(AlignPosition);
		}

		if(AlignRotation)
		{
			FVector Direction = Root.WorldLocation - Player.ActorLocation;
			FRotator LookAtRotation = Math::MakeRotFromX(Direction);

			Player.SetActorRotation(FRotator(Player.ActorRotation.Pitch, LookAtRotation.Yaw, Player.ActorRotation.Roll));
		}

		if(Player.IsCody())
		{
			PlayAnimation(Player, CodyAnim);
		}
		else
		{
			PlayAnimation(Player, MayAnim);
		}

		if(HasControl())
		{
			AnimNotifyDelegate.BindUFunction(this, n"OnAnimationNotify");
			Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);
		}
	}

	UFUNCTION()
	void OnAnimationNotify(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if(OnInteractedForceFeedback != nullptr && Player != nullptr)
			Player.PlayForceFeedback(OnInteractedForceFeedback, false, false, n"FlashlightInteracted");

		PerformSwitch();
	}

	UFUNCTION()
	void PlayAnimation(AHazePlayerCharacter Player, UAnimSequence AnimationToPlay)
	{
		Player.PlayEventAnimation(Animation = AnimationToPlay);
	}

	UFUNCTION(NetFunction)
	void PerformSwitch()
	{
		bIsActive = !bIsActive;
		SwitchLight(bIsActive);

		if(InteractingPlayer != nullptr && PillowfortVOBank != nullptr)
		{
			if(InteractingPlayer.IsMay() && !bHasPlayedMayVOEvent && !bIsActive)
			{
				PillowfortVOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomPillowFortFlashlightInteractMay", nullptr);
				bHasPlayedMayVOEvent = true;
			}
			else if(InteractingPlayer.IsCody() && !bHasPlayedCodyVOEvent && bIsActive)
			{
				PillowfortVOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomPillowFortFlashlightInteractCody", nullptr);
				bHasPlayedCodyVOEvent = true;
			}
		}

		UHazeAkComponent::HazePostEventFireForget(PlayButtonAudioEvent, GetActorTransform());
		
		if(bIsActive)
			UHazeAkComponent::HazePostEventFireForget(PlayLightOnAudioEvent, GetActorTransform());

		InteractingPlayer = nullptr;
		InteractionComp.Enable(n"InUse");
	}

	UFUNCTION(BlueprintEvent)
	void SwitchLight(bool Active)
	{
		
	}
}