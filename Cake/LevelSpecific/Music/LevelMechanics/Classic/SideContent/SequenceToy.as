import Vino.Movement.Components.GroundPound.GroundPoundGuideComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

enum ESequenceToyState
{
	None,
	PreGame,
	Display,
	Input,
	PostGame
}

struct FSequenceToyButtonSettings
{
	UPROPERTY()
	UMaterialInstance Material;

	UPROPERTY()
	ASpotLight SpotLight;

	// Audio played when the button is pressed or highlighted as part of the game sequence.
	UPROPERTY()
	UAkAudioEvent HighlightAudioEvent;
}

class USequenceToyButtonComponent : UStaticMeshComponent
{
	default CollisionProfileName = n"BlockOnlyPlayerCharacter";

	UPROPERTY(NotVisible)
	USpotLightComponent Light;
	UPROPERTY(NotVisible)
	UAkAudioEvent HighlightAudioEvent;
	UPROPERTY(NotVisible)
	int Index = -1;

	UMaterialInstanceDynamic DynamicMaterial;
	float InitialIntensity;
	FLinearColor InitialEmissiveTint;
	FVector InitialLocation;
	FHazeAcceleratedFloat VerticalOffset;
	float TargetOffset;
	bool bIsPressed;
	bool bIsHighlighted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialLocation = RelativeLocation;
		DynamicMaterial = CreateDynamicMaterialInstance(0);
		InitialEmissiveTint = DynamicMaterial.GetVectorParameterValue(n"Emissive Tint");

		if (Light != nullptr)
		{
			InitialIntensity = Light.Intensity;
			Light.LightColor = InitialEmissiveTint;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TargetOffset = bIsPressed ? -10.f : 0.f;

		if (Index >= 0)
			VerticalOffset.AccelerateTo(TargetOffset, 0.3f, DeltaTime);
		else
			VerticalOffset.SpringTo(TargetOffset, 130.f, 0.3f, DeltaTime);

		RelativeLocation = InitialLocation + UpVector * VerticalOffset.Value;
	}

	void Press()
	{
		if (Index >= 0)
			Highlight(true);
		bIsPressed = true;
	}

	void Release()
	{
		if (Index >= 0)
			Highlight(false);
		bIsPressed = false;
	}

	void GroundPound()
	{
		VerticalOffset.Value = -30.f;
	}

	void Highlight(bool bEnable)
	{
		Highlight(bEnable ? 1.f : 0.f);
	}

	void Highlight(float Intensity)
	{
		if (Light != nullptr)
			Light.SetIntensity(InitialIntensity * Intensity);

		if (DynamicMaterial != nullptr)
			DynamicMaterial.SetVectorParameterValue(n"Emissive Tint", InitialEmissiveTint * Intensity);

		bIsHighlighted = Intensity > 0.f;
	}
}

event void FOnGameStart();
event void FOnGameEnd(bool bWasCompleted);
event void FOnSequenceButtonPressed(USequenceToyButtonComponent Button);
event void FOnSequenceButtonReleased(USequenceToyButtonComponent Button);

class ASequenceToy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"BlockOnlyPlayerCharacter";

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USequenceToyButtonComponent ActivationButton;
	default ActivationButton.Index = -1;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UGroundPoundGuideComponent GroundPoundGuideComponent;
	default GroundPoundGuideComponent.ActivationRadius = 240.f;
	default GroundPoundGuideComponent.TargetRadius = 115.f;
	default GroundPoundGuideComponent.RelativeLocation = FVector(0.f, 0.f, 800.f);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WidgetLocation;
	default WidgetLocation.RelativeLocation = FVector(0.f, 0.f, 140.f);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent WidgetSphere;
	default WidgetSphere.SphereRadius = 1250.f;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundCallbackComponent;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactCallbackComponent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 12000.f;

	UPROPERTY(NotVisible)
	TArray<USequenceToyButtonComponent> SequenceButtons;

	// Whether or not to automatically align lights when modifying the actor.
	UPROPERTY(Category = "Sequence Toy")
	bool bAutoAlignLights = true;

	// Whether to restart the game automatically on incorrect input.
	UPROPERTY(NotVisible, Category = "Sequence Toy")
	bool bAutoRestart = false;

	// The sequence that is to be executed.
	UPROPERTY(NotVisible, Category = "Sequence Toy")
	TArray<int> SequenceOrder;

	UPROPERTY(Category = "Sequence Toy|Buttons")
	UStaticMesh SequenceButtonMesh = nullptr;

	UPROPERTY(Category = "Sequence Toy|Buttons")
	ASpotLight ActivationButtonLight = nullptr;

	UPROPERTY(Category = "Sequence Toy|Buttons")
	TArray<FSequenceToyButtonSettings> ButtonSettings;

	// Time spent playing the start game animation.
	UPROPERTY(Category = "Sequence Toy|Timing")
	float PreGameDuration = 0.7f;

	// Time spent playing the end game animation.
	UPROPERTY(Category = "Sequence Toy|Timing")
	float PostGameDuration = 1.f;

	// Duration in which buttons are highlighted for.
	UPROPERTY(Category = "Sequence Toy|Timing")
	float HighlightDuration = 0.6f;

	// Interval between highlighting buttons, very low values make consecutive buttons hard to distinguish.
	UPROPERTY(Category = "Sequence Toy|Timing")
	float HighlightInterval = 0.1f;

	// Adds a delay between completing a sequence and the next round's highlighting.
	UPROPERTY(Category = "Sequence Toy|Timing")
	float RoundDelay = 1.0f;

	UPROPERTY(NotVisible, Category = "Sequence Toy")
	ESequenceToyState GameState = ESequenceToyState::None;

	UPROPERTY(EditDefaultsOnly, Category = "Sequence Toy")
	TSubclassOf<UHazeUserWidget> WidgetClass;

	// Audio played when the game starts.
	UPROPERTY(Category = "Sequence Toy|Audio")
	UAkAudioEvent GameStartAudioEvent;

	// Audio played when an incorrect input is pressed.
	UPROPERTY(Category = "Sequence Toy|Audio")
	UAkAudioEvent CorrectAudioEvent;

	// Audio played when an incorrect input is pressed.
	UPROPERTY(Category = "Sequence Toy|Audio")
	UAkAudioEvent IncorrectAudioEvent;

	UPROPERTY(Category = "Sequence Toy|Events")
	FOnGameStart OnGameStart;

	UPROPERTY(Category = "Sequence Toy|Events")
	FOnGameEnd OnGameEnd;

	UPROPERTY(Category = "Sequence Toy|Events")
	FOnSequenceButtonPressed OnSequenceButtonPressed;

	UPROPERTY(Category = "Sequence Toy|Events")
	FOnSequenceButtonReleased OnSequenceButtonReleased;

	// How many rounds are added to the random sequence.
	UPROPERTY(Category = "Sequence Toy|Sequences")
	int NumRounds = 10;

	// Maximum amount of the same index in a row, 1 or below means an index is never repeated consecutively.
	UPROPERTY(Category = "Sequence Toy|Sequences")
	int MaxConsecutive = 2;

	// Scales the weight decrease per consecutive, higher value lowers the likelyhood of consecutive numbers.
	UPROPERTY(Category = "Sequence Toy|Sequences")
	float ConsecutiveScale = 1.2f;

	// Scales the weight decrease per occurrence, higher value lowers the likelyhood of a previous number to show up again; more likely to display all numbers at least once.
	UPROPERTY(Category = "Sequence Toy|Sequences")
	float OccurrenceScale = 1.4f;

	int SequenceIndex = 0;
	int SequenceLength = 1;
	bool bPauseHighlight = false;
	float Timer = 0.f;
	float ActivationLightTimer = 0.f;

	// We need to keep track of which players are touching the toy
	// since impact callback no longer triggers when colliding against the same object
	TArray<AHazePlayerCharacter> PressingPlayers;

	// Track one button per player, so we can press multiple ones
	TPerPlayer<USequenceToyButtonComponent> PressedButtons;
	TPerPlayer<UHazeUserWidget> Widgets;

	// Aligns lights to the sequence toy buttons.
	UFUNCTION(CallInEditor, Category = "Sequence Toy")
	void AlignLights()
	{
		for (int i = 0; i < SequenceButtons.Num(); ++i)
		{
			ASpotLight SpotLight = ButtonSettings[i].SpotLight;

			if (SpotLight == nullptr)
				continue;

			float Yaw = (360.f / ButtonSettings.Num()) * i;

			FVector Location = ActorLocation;
			Location += FMath::RotatorFromAxisAndAngle(ActorUpVector, Yaw + ActorRotation.Yaw).ForwardVector * 300.f;
			Location -= ActorUpVector * 80.f;

			FSequenceToyButtonSettings Settings = ButtonSettings[i];
			SpotLight.ActorLocation = Location;
			SpotLight.ActorRotation = ActorUpVector.Rotation();
		}

		if (ActivationButtonLight != nullptr)
			ActivationButtonLight.ActorLocation = ActorLocation - ActorUpVector * 80.f;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Dispose of old buttons
		for (USequenceToyButtonComponent Button : SequenceButtons)
		{
			if (Button != nullptr)
			{
				if (Button.Light != nullptr)
					Button.Light.DestroyComponent(this);

				Button.DestroyComponent(this);
			}
		}
		SequenceButtons.Empty(ButtonSettings.Num());

		// Create new buttons, rotated into place
		for (int i = 0; i < ButtonSettings.Num(); ++i)
		{
			float Angle = (360.f / ButtonSettings.Num()) * i;

			USequenceToyButtonComponent ButtonComponent = USequenceToyButtonComponent::Create(this, FName("SequenceToyButton" + i));
			ButtonComponent.SetStaticMesh(SequenceButtonMesh);
			ButtonComponent.RelativeRotation = FMath::RotatorFromAxisAndAngle(FVector::UpVector, Angle);
			ButtonComponent.Index = i;
			ButtonComponent.HighlightAudioEvent = ButtonSettings[i].HighlightAudioEvent;

			// Override material from settings
			if (ButtonSettings[i].Material != nullptr)
				ButtonComponent.SetMaterial(0, ButtonSettings[i].Material);

			// Get spotlight component from actor
			if (ButtonSettings[i].SpotLight != nullptr)
				ButtonComponent.Light = USpotLightComponent::Get(ButtonSettings[i].SpotLight);

			SequenceButtons.Add(ButtonComponent);
		}

		// Get activation button light from component
		if (ActivationButtonLight != nullptr)
			ActivationButton.Light = USpotLightComponent::Get(ActivationButtonLight);

		if (bAutoAlignLights)
			AlignLights();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundCallbackComponent.OnActorGroundPounded.AddUFunction(this, n"HandlePlayerGroundPound");
		ImpactCallbackComponent.OnActorDownImpactedByPlayer.AddUFunction(this, n"HandlePlayerEnter");
		ImpactCallbackComponent.OnDownImpactEndingPlayer.AddUFunction(this, n"HandlePlayerLeave");
		WidgetSphere.OnComponentBeginOverlap.AddUFunction(this, n"HandleWidgetOverlapBegin");
		WidgetSphere.OnComponentEndOverlap.AddUFunction(this, n"HandleWidgetOverlapEnd");

		// Turn off all lights by default
		for (int i = 0; i < SequenceButtons.Num(); ++i)
			SequenceButtons[i].Highlight(false);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for (USequenceToyButtonComponent Button : SequenceButtons)
		{
			if (Button != nullptr)
			{
				if (Button.Light != nullptr)
					Button.Light.DestroyComponent(this);

				Button.DestroyComponent(this);
			}
		}
		SequenceButtons.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (auto Player : PressingPlayers)
			UpdatePressedButton(Player);

		switch (GameState)
		{
		case ESequenceToyState::None:
			TickIdle(DeltaTime);
			break;
		case ESequenceToyState::PreGame:
			TickPreGame(DeltaTime);
			break;
		case ESequenceToyState::Display:
			TickDisplay(DeltaTime);
			break;
		case ESequenceToyState::PostGame:
			TickPostGame(DeltaTime);
			break;
		}
	}

	void TickIdle(float DeltaTime)
	{
		ActivationLightTimer += DeltaTime;

		float Intensity = 0.5f + FMath::Sin(ActivationLightTimer) / 2.f;
		ActivationButton.Highlight(Intensity);
	}

	void TickPreGame(float DeltaTime)
	{
		if (Timer <= 0.f)
		{
			for (int i = 0; i < SequenceButtons.Num(); ++i)
				SequenceButtons[i].Highlight(false);

			GameState = ESequenceToyState::Display;
			Timer = HighlightDuration;
			return;
		}

		// Circle-fill animation when the game begins
		float Alpha = 1.f - Timer / PreGameDuration;
		for (int i = 0; i < SequenceButtons.Num(); ++i)
			SequenceButtons[i].Highlight((1.f / (SequenceButtons.Num()) * i) <= Alpha);

		Timer -= DeltaTime;
	}

	void TickDisplay(float DeltaTime)
	{
		if (Timer > 0.f)
		{
			Timer -= DeltaTime;
			return;
		}

		if (SequenceIndex >= SequenceLength)
		{
			// Unhighlight previous button and move into input state
			if (SequenceIndex > 0 && SequenceIndex <= SequenceOrder.Num())
				SequenceButtons[SequenceOrder[SequenceIndex - 1]].Highlight(false);

			SequenceIndex = 0;
			GameState = ESequenceToyState::Input;
		}
		else if (bPauseHighlight)
		{
			// Unhighlight previous button, then we wait for interval
			if (SequenceIndex > 0 && SequenceIndex <= SequenceOrder.Num())
				SequenceButtons[SequenceOrder[SequenceIndex - 1]].Highlight(false);

			Timer = HighlightInterval;
			bPauseHighlight = false;
		}
		else
		{
			// Highlight the button found in sequence order at index
			if (SequenceIndex >= 0 && SequenceIndex < SequenceOrder.Num())
			{
				USequenceToyButtonComponent Button = SequenceButtons[SequenceOrder[SequenceIndex]];
				Button.Highlight(true);
				PlayAudioEvent(Button.HighlightAudioEvent);
			}

			// Flag to add interval between highlighting, ensures light is turned off
			// between consecutive highlights
			bPauseHighlight = true;
			++SequenceIndex;
			Timer = HighlightDuration;
		}
	}

	bool bWasHighlight;
	void TickPostGame(float DeltaTime)
	{
		if (Timer <= 0.f)
		{
			for (int i = 0; i < SequenceButtons.Num(); ++i)
				SequenceButtons[i].Highlight(false);

			GameState = ESequenceToyState::None;
			bWasHighlight = false;
			return;
		}

		// Blinking animation when the game ends
		float Alpha = (1.f - (Timer / PostGameDuration)) * 6.f;
		bool bHighlight = (FMath::FloorToInt(Alpha) % 2 == 0);

		for (int i = 0; i < SequenceButtons.Num(); ++i)
			SequenceButtons[i].Highlight(bHighlight);

		if (bHighlight && !bWasHighlight)
		{
			HazeAkComp.HazePostEvent(CorrectAudioEvent);
		}

		Timer -= DeltaTime;
		bWasHighlight = bHighlight;
	}

	void UpdatePressedButton(AHazePlayerCharacter Player)
	{
		FHitResult Down = Player.MovementComponent.DownHit;
		USequenceToyButtonComponent Button = Cast<USequenceToyButtonComponent>(Down.Component);

		if (Button == nullptr || Button == ActivationButton)
		{
			if (PressedButtons[Player] != nullptr)
				ReleaseButton(Player);
		}
		else
		{
			if (Button == PressedButtons[Player])
				return;

			PressButton(Player, Button);
		}
	}

	void StartGame(bool bRegenerateSequence)
	{
		if (HasControl())
		{
			if (bRegenerateSequence)
				GenerateSequence(SequenceOrder);
			
			NetStartGame(SequenceOrder);
		}
	}

	void EndGame(bool bWasCompleted)
	{
		if (HasControl())
			NetEndGame(bWasCompleted);
	}

	void FinishRound()
	{
		if (HasControl())
			NetFinishRound();
	}

	void PressButton(AHazePlayerCharacter Player, USequenceToyButtonComponent Button)
	{
		if (Player.HasControl())
			NetPressButton(Player, Button);
	}

	void ReleaseButton(AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
			NetReleaseButton(Player);
	}

	UFUNCTION(NetFunction)
	void NetStartGame(TArray<int> NewSequence)
	{
		if (NewSequence.Num() > 0)
			SequenceOrder = NewSequence;

		if (ButtonSettings.Num() <= 0 || SequenceOrder.Num() <= 0 || SequenceButtons.Num() <= 0)
			return;

		SequenceIndex = 0;
		SequenceLength = 1;
		GameState = ESequenceToyState::PreGame;
		Timer = PreGameDuration;
		bPauseHighlight = false;
		ActivationLightTimer = 0.f;
		ActivationButton.Highlight(1.f);
		PlayAudioEvent(GameStartAudioEvent);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			HideWidget(Player);

		if (OnGameStart.IsBound())
			OnGameStart.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetEndGame(bool bWasCompleted)
	{
		GameState = bWasCompleted ? ESequenceToyState::PostGame : ESequenceToyState::None;
		Timer = PostGameDuration;
		ActivationLightTimer = 0.f;

		if (!bAutoRestart)
		{
			for (auto Player : Game::Players)
			{
				bool bIsOverlapping = Trace::ComponentOverlapComponent(
					Player.CapsuleComponent,
					WidgetSphere,
					WidgetSphere.WorldLocation,
					WidgetSphere.ComponentQuat,
					bTraceComplex = false);

				if (!bIsOverlapping)
					continue;

				ShowWidget(Player);
			}
		}

		if (OnGameEnd.IsBound())
			OnGameEnd.Broadcast(bWasCompleted);
	}

	UFUNCTION(NetFunction)
	void NetFinishRound()
	{
		// This was the last round
		if (SequenceLength >= SequenceOrder.Num())
		{
			EndGame(true);
			return;
		}

		++SequenceLength;
		SequenceIndex = 0;
		GameState = ESequenceToyState::Display;
		Timer = RoundDelay;
		bPauseHighlight = false;
	}

	UFUNCTION(NetFunction)
	void NetPressButton(AHazePlayerCharacter Player, USequenceToyButtonComponent Button)
	{
		// We need to check this before we assign the player's pressed button below
		bool bWasAlreadyPressed = IsAnyPressing(Button);

		PressedButtons[Player] = Button;
		if (Button == nullptr || bWasAlreadyPressed)
			return;

		Button.Press();

		// Only handle game state on control side
		if (GameState != ESequenceToyState::Input || Button == ActivationButton)
			return;

		// Input was incorrect, restart or end the game
		if (PressedButtons[Player].Index != SequenceOrder[SequenceIndex])
		{
			PlayAudioEvent(IncorrectAudioEvent);

			if (bAutoRestart)
				StartGame(true);
			else
				EndGame(false);
		}
		else
		{
			PlayAudioEvent(CorrectAudioEvent);

			if (++SequenceIndex >= SequenceLength)
				FinishRound();
		}
	}
	
	UFUNCTION(NetFunction)
	void NetReleaseButton(AHazePlayerCharacter Player)
	{
		USequenceToyButtonComponent Button = PressedButtons[Player];

		// Remove it from the array first so we can check if the other player is still pressing it
		PressedButtons[Player] = nullptr;

		if (Button == nullptr || IsAnyPressing(Button))
			return;

		Button.Release();

		if (Button.Index >= 0)
			OnSequenceButtonReleased.Broadcast(Button);
	}
	
	UFUNCTION()
	void HandlePlayerGroundPound(AHazePlayerCharacter Player)
	{
		if (Player.MovementComponent.DownHit.Component != ActivationButton)
			return;

		// Generate a new sequence on control side; sent to remote
		StartGame(true);

		ActivationButton.GroundPound();
	}

	UFUNCTION()
	void HandlePlayerEnter(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		if (!Player.HasControl())
			return;

		PressingPlayers.AddUnique(Player);
	}

	UFUNCTION()
	void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		if (!Player.HasControl())
			return;

		if (PressedButtons[Player] != nullptr)
			ReleaseButton(Player);

		PressingPlayers.Remove(Player);
	}

	UFUNCTION()
	void HandleWidgetOverlapBegin(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr && !HasGameStarted())
			ShowWidget(Player);
	}

	UFUNCTION()
	void HandleWidgetOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		 UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
			HideWidget(Player);
	}

	bool HasGameStarted()
	{
		return GameState != ESequenceToyState::None;
	}

	bool IsAnyPressing(USequenceToyButtonComponent Button)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (PressedButtons[Player] == Button)
				return true;
		}

		return false;
	}

	void ShowWidget(AHazePlayerCharacter Player)
	{
		if (Player == nullptr || Widgets[Player] != nullptr || !WidgetClass.IsValid())
			return;

		Widgets[Player] = Player.AddWidget(WidgetClass);
		Widgets[Player].AttachWidgetToComponent(WidgetLocation);
	}

	void HideWidget(AHazePlayerCharacter Player)
	{
		if (Player == nullptr || Widgets[Player] == nullptr)
			return;

		Player.RemoveWidget(Widgets[Player]);
		Widgets[Player] = nullptr;
	}

	void PlayAudioEvent(UAkAudioEvent AudioEvent)
	{
		if (AudioEvent != nullptr)
			HazeAkComp.HazePostEvent(AudioEvent);
	}

	// Generates a new random sequence.
	void GenerateSequence(TArray<int>& Sequence)
	{
		Sequence.Empty(NumRounds);

		if (NumRounds <= 0)
			return;

		TArray<float> Weights;
		for (int i = 0; i < NumRounds; ++i)
		{
			CalculateWeights(Sequence, Weights);

			float Distance = FMath::FRand();
			for (int j = 0; j < Weights.Num(); ++j)
			{
				Distance -= Weights[j];
				if (Distance <= 0.f)
				{
					// Print("Index " + j + " was chosen with a weight of " + Weights[j]);
					Sequence.Add(j);
					break;
				}
			}
		}
	}

	// Calculates random weights to ensure a decent sequence pattern is created.
	void CalculateWeights(const TArray<int>& CurrentSequence, TArray<float>& Weights)
	{
		Weights.Empty(SequenceButtons.Num());

		// If the sequence is empty, all numbers have equal probability
		if (CurrentSequence.Num() <= 0)
		{
			float Weight = 1.f / float(SequenceButtons.Num());
			for (int i = 0; i < SequenceButtons.Num(); ++i)
				Weights.Add(Weight);
		}
		else
		{
			float WeightSum = 0.f;
			for (int i = 0; i < SequenceButtons.Num(); ++i)
			{
				// Ensure we're not adding too many in a row
				int NumConsecutive = GetNumConsecutive(CurrentSequence, i);

				if (NumConsecutive < MaxConsecutive)
				{
					// Calculate the percentage of indices this index is populating
					int NumOccurrences = GetNumOccurrences(CurrentSequence, i);

					// Inverted; the more often it occurs in, the less likely it should be to occur again
					float Weight = 1.f - NumOccurrences / float(CurrentSequence.Num());

					if (NumConsecutive > 0 && ConsecutiveScale != 0.f)
						Weight /= FMath::Pow(NumConsecutive + 1, ConsecutiveScale);

					if (NumOccurrences > 0 && OccurrenceScale != 0.f)
						Weight /= FMath::Pow(NumOccurrences + 1, OccurrenceScale);

					// Reduce odds of selecting a neighbouring index
					if (IsNeighbour(i, CurrentSequence.Last()))
						Weight *= 0.8f;

					// Add to array and sum, which is used to normalize
					Weights.Add(Weight);
					WeightSum += Weight;
				}
				else
				{
					Weights.Add(0.f);
				}
			}

			// Normalize
			for (int i = 0; i < Weights.Num(); ++i)
				Weights[i] /= WeightSum;
		}
	}

	// Number of times the index appears in the sequence.
	int GetNumOccurrences(const TArray<int>& Sequence, int Index)
	{
		int Occurrences = 0;
		for (int i = 0; i < Sequence.Num(); ++i)
			if (Sequence[i] == Index)
				++Occurrences;
		return Occurrences;
	}

	// Number of times the index appears consecutively at the end of the sequence.
	int GetNumConsecutive(const TArray<int>& Sequence, int Index)
	{
		int Consecutive = 0;
		for (int i = Sequence.Num() - 1; i > 0; --i)
		{
			if (Sequence[i] != Index)
				break;

			++Consecutive;
		}
		return Consecutive;
	}

	// Whether the two indices are neighbours.
	bool IsNeighbour(int A, int B)
	{
		int Distance = FMath::Abs(A - B);
		return Distance == 1 || Distance == SequenceButtons.Num() - 1;
	}
}