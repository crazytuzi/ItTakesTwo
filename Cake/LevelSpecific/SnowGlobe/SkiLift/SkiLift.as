event void FSkiLiftEvent();

class ASkiLift : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY()
	UAnimSequence ExitAnimation;

	UPROPERTY()
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettings;

	UPROPERTY()
	TSubclassOf<UHazeInputButton> PlayerInteractionWidgetClass;

	UPROPERTY()
	FSkiLiftEvent OnSkiLiftExitEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RaiseBarAudioEvent;

	private TMap<EHazePlayer, bool> InteractingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Assign delegates
		OnSkiLiftExitEvent.AddUFunction(this, n"OnSkiLiftExit");
	}

	// Teleports and attaches players to ski lift
	UFUNCTION()
	void StartRiding()
	{
		// If intro cutscene was skipped the skilift's base bone will be stuck (when playing networked)
		Mesh.HazeForceUpdateAnimation(true);

		for(auto PlayerCharacter : Game::GetPlayers())
		{
			// Teleport player to ski lift
			FTransform AttachSocketTransform = Mesh.GetSocketTransform(GetAttachSocketNameForPlayer(PlayerCharacter));
			PlayerCharacter.SetActorLocation(AttachSocketTransform.Location);
			PlayerCharacter.SetActorRotation(AttachSocketTransform.Rotation);

			// Start capability system
			PlayerCharacter.AddCapabilitySheet(PlayerCapabilitySheet, Instigator = this);
			PlayerCharacter.SetCapabilityAttributeObject(n"SkiLift", this);
		}
	}

	void StartInteracting(EHazePlayer Player)
	{
		InteractingPlayers.Add(Player, true);
	}

	void StopInteracting(EHazePlayer Player)
	{
		InteractingPlayers.Remove(Player);
	}

	UFUNCTION()
	bool BothPlayersAreInteracting() const
	{
		if(InteractingPlayers.Num() <= 1.f)
			return false;

		for(auto PlayerCharacter : Game::GetPlayers())
		{
			if(!InteractingPlayers[PlayerCharacter.Player])
				return false;
		}

		return true;
	}

	void RaiseBar()
	{
		// Play exit animation
		FHazePlaySlotAnimationParams AnimationParams;
		AnimationParams.Animation = ExitAnimation;
		AnimationParams.bPauseAtEnd = true;
		AnimationParams.bLoop = false;
		UHazeAkComponent::HazePostEventFireForget(RaiseBarAudioEvent, this.GetActorTransform());

		Mesh.PlaySlotAnimation(AnimationParams);
	}

	FName GetAttachSocketNameForPlayer(const AHazePlayerCharacter& PlayerCharacter) const
	{
		return PlayerCharacter.IsMay() ? n"May_Attach" : n"Cody_Attach";
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSkiLiftExit()
	{
		RaiseBar();
		InteractingPlayers.Reset();
	}
}