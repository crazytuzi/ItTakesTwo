import Vino.Interactions.InteractionComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Interactions.DoubleInteractComponent;

event void FUpdateKaleidoscopeRotationValue(float Value);
event void FKaleidoscopeInteractionCompleted();

//audio stuff to add :
//HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_Kaleidoscope_Top_Rotation", ValueToSet);


class AKaleidoscopeTopInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RotatingKaleidoscopeTopStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RotatingKaleidoscopeTopStopAudioEvent;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent InteractionComp01;

	UPROPERTY(DefaultComponent, Attach = InteractionComp01)
	USceneComponent AttachComponent01;

	UPROPERTY(DefaultComponent, Attach = AttachComponent01)
	USkeletalMeshComponent EditorSkelMesh01;
	default EditorSkelMesh01.bIsEditorOnly = true;
	default EditorSkelMesh01.bHiddenInGame = true;
	default EditorSkelMesh01.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent InteractionComp02;

	UPROPERTY(DefaultComponent, Attach = InteractionComp02)
	USceneComponent AttachComponent02;

	UPROPERTY(DefaultComponent, Attach = AttachComponent02)
	USkeletalMeshComponent EditorSkelMesh02;
	default EditorSkelMesh02.bIsEditorOnly = true;
	default EditorSkelMesh02.bHiddenInGame = true;
	default EditorSkelMesh02.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent CodyInputSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent MayInputSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent CurrentYawSync;

	UPROPERTY()
	TSubclassOf<UHazeCapability> KaleidoscopeTopInteractionCapability;

	UPROPERTY()
	FUpdateKaleidoscopeRotationValue UpdateRotationValue;

	UPROPERTY()
	FKaleidoscopeInteractionCompleted KaleidoscopeInteractionCompleted;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	float CodyLastInput = 0.f;
	float MayLastInput = 0.f;

	float CurrentYaw = 0.f;
	float YawLastTick = 0.f;
	float RotationDelta = 0.f;
	float RotationMultiplier = 30.f;
	bool bBothPlayersInteracting = false;
	bool bFinishedWithInteraction = false;

	bool bHasStartedAudio = false;

	TArray<AHazePlayerCharacter> PlayersUsingInteraction;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp01.OnActivated.AddUFunction(this, n"InteractionCompActivated");
		InteractionComp02.OnActivated.AddUFunction(this, n"InteractionCompActivated");
		
		CodyInputSync.OverrideControlSide(Game::GetCody()); 
		MayInputSync.OverrideControlSide(Game::GetMay());

		DoubleInteract.OnTriggered.AddUFunction(this, n"BothPlayersInteracting");
	}

	UFUNCTION()
	void InteractionCompActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		SetInteractionPointEnabled(Comp, false);
		Player.AddCapability(KaleidoscopeTopInteractionCapability);
		Player.SetCapabilityActionState(n"PushingKaleidoscopeTop", EHazeActionState::Active);
		Player.SetCapabilityAttributeObject(n"KaleidoscopeTopInteraction", this);
		Player.SetCapabilityAttributeObject(n"InteractionComp", Comp);

		if (Comp == InteractionComp01)
			Player.SetCapabilityAttributeObject(n"AttachComp", AttachComponent01);
		if (Comp == InteractionComp02)
			Player.SetCapabilityAttributeObject(n"AttachComp", AttachComponent02);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CheckIfAudioShouldBeEnabled();

		if (bBothPlayersInteracting)
		{
			RotationDelta = CurrentYawSync.Value - YawLastTick;
			YawLastTick = CurrentYawSync.Value;
			RotationDelta = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 0.4f), FVector2D(0.f, 1.f), RotationDelta);
			HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_Kaleidoscope_Top_Rotation", RotationDelta);
			HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_Kaleidoscope_Top_Rotation_OnStop", RotationDelta);
			HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_Kaleidoscope_Top_Progression", CurrentYawSync.Value);
		}

		if (CodyInputSync.Value > 0.5f && MayInputSync.Value > 0.5f && bBothPlayersInteracting)
		{
			if (HasControl())
			{
				CurrentYaw += DeltaTime * RotationMultiplier;
				CurrentYawSync.SetValue(CurrentYaw);
				
				if (CurrentYawSync.Value > 180.f && !bFinishedWithInteraction)
				{
					bFinishedWithInteraction = true;
					NetDoneWithKaleidoscopeInteraction();
				}
			}
		}

		MeshRoot.SetRelativeRotation(FRotator(0.f, CurrentYawSync.Value, 0.f));
		UpdateRotationValue.Broadcast(CurrentYawSync.Value);
	}

	UFUNCTION(NetFunction)
	void NetDoneWithKaleidoscopeInteraction()
	{
		for(AHazePlayerCharacter Player : PlayersUsingInteraction)
		{
			Player.SetCapabilityActionState(n"PushingKaleidoscopeTop", EHazeActionState::Inactive);
			InteractionComp01.DisableForPlayer(Player, n"KaleidoscopeDone");
			InteractionComp02.DisableForPlayer(Player, n"KaleidoscopeDone");
		} 
		KaleidoscopeInteractionCompleted.Broadcast();
	}

	void CheckIfAudioShouldBeEnabled()
	{
		if (bBothPlayersInteracting && !bHasStartedAudio)
		{
			bHasStartedAudio = true;
			HazeAkComp.HazePostEvent(RotatingKaleidoscopeTopStartAudioEvent);
		}

		if (!bBothPlayersInteracting && bHasStartedAudio)
		{
			bHasStartedAudio = false;
			HazeAkComp.HazePostEvent(RotatingKaleidoscopeTopStopAudioEvent);
		}
	}

	void UpdatePlayerArray(AHazePlayerCharacter Player, bool bShouldAdd)
	{
		if (bShouldAdd)
		{
			DoubleInteract.StartInteracting(Player);
			PlayersUsingInteraction.AddUnique(Player);
		}
		else
		{
			DoubleInteract.CancelInteracting(Player);
			PlayersUsingInteraction.Remove(Player);
		}
	}

	void SetInteractionPointEnabled(UInteractionComponent Comp, bool bEnabled)
	{
		bEnabled ? Comp.Enable(n"PlayerUsingInteraction") : Comp.Disable(n"PlayerUsingInteraction");
	}

	void AddPlayerInput(AHazePlayerCharacter Player, float Input)
	{
		if (!Player.HasControl())
			return;

		if (Player == Game::GetCody())
			CodyInputSync.SetValue(Input);
		else 
			MayInputSync.SetValue(Input);
	}

	UFUNCTION()
	void BothPlayersInteracting()
	{
		bBothPlayersInteracting = true;
	}
}