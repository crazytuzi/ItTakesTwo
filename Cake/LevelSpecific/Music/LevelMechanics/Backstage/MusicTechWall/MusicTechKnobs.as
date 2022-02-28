import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BackstageAudio.MusicTechKnobsAudioComponent;
event void FMusicTechKnobsSignature(float LeftRotationRate, float RightRotationRate);

class AMusicTechKnobs : AHazeActor
	{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UStaticMeshComponent LeftKnobMesh;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UStaticMeshComponent RightKnobMesh;

	UPROPERTY()
	FMusicTechKnobsSignature RotationRateUpdate;

	UPROPERTY()
	UHazeLocomotionFeatureBase CodyFeature;

	UPROPERTY()
	AActor TeleportLocationActor;

	UPROPERTY()
	AHazeCameraActor ConnectedCamera;

	UPROPERTY()
	AActor LeftKnob;

	UPROPERTY()
	AActor RightKnob;
	
	UPROPERTY(Category = "Audio")
	TSubclassOf<UHazeCapability> AudioScrubbingCapabaility;

	UPROPERTY(DefaultComponent, Category = "Audio")
	UMusicTechKnobsAudioComponent TechKnobsAudioComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		SetControlSide(Game::GetCody());
		
		UClass AudioScrubbingCapabilityClass = AudioScrubbingCapabaility.Get();
		if(AudioScrubbingCapabilityClass != nullptr)
			AddCapability(AudioScrubbingCapabilityClass);
	}

	void UpdateInputs(FVector2D Inputs)
	{		
		RotationRateUpdate.Broadcast(Inputs.X, Inputs.Y);
	}

	UFUNCTION()
	void ActivateTechKnobs()
	{
		if (!HasControl())
			return;

		NetActivateTechKnobs();	
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetActivateTechKnobs()
	{

		AHazePlayerCharacter Player = Game::GetCody();	

		Player.SetCapabilityActionState(n"ControllingMusicTechKnob", EHazeActionState::Active);
		Player.SetCapabilityAttributeObject(n"MusicKnobActor", this);
		FTutorialPrompt PromptLeft;
		PromptLeft.MaximumDuration = 10.f;
		PromptLeft.DisplayType = ETutorialPromptDisplay::LeftStick_Rotate_CW;
		PromptLeft.AlternativeDisplayType = ETutorialAlternativePromptDisplay::KeyBoard_LeftRight;
		ShowTutorialPrompt(Player, PromptLeft, this);

		FTutorialPrompt PromptRight;
		PromptRight.MaximumDuration = 10.f;
		PromptRight.DisplayType = ETutorialPromptDisplay::RightStick_Rotate_CW;
		PromptRight.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Mouse_LeftRightButton;
		ShowTutorialPrompt(Player, PromptRight, this);

		LeftKnob.AttachToComponent(Player.Mesh, n"LeftHand_IK", EAttachmentRule::SnapToTarget);			
		RightKnob.AttachToComponent(Player.Mesh, n"RightHand_IK", EAttachmentRule::SnapToTarget);	
	}

	UFUNCTION()
	void StopInteractingWithKnobs()
	{
		Game::GetCody().SetCapabilityActionState(n"ControllingMusicTechKnob", EHazeActionState::Inactive);
		LeftKnob.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		RightKnob.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

}
