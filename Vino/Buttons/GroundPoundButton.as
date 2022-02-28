import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FOnButtonGroundPoundStarted(AHazePlayerCharacter Player);
event void FOnButtonGroundPoundCompleted(AHazePlayerCharacter Player);
event void FOnButtonReset();

class AGroundPoundButton : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;

	FHazeConstrainedPhysicsValue PhysicsValue;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent ButtonMesh;
    default ButtonMesh.StaticMesh = Asset("/Game/Environment/Props/Fantasy/Shed/Machines/Machine_01_Power_Button_01.Machine_01_Power_Button_01");
    default ButtonMesh.RelativeScale3D = FVector(2.f, 2.f, 2.f);
    default ButtonMesh.RelativeRotation = FRotator(90.f, 0.f, 0.f);

    UPROPERTY(DefaultComponent)
    UGroundPoundedCallbackComponent GroundPoundComp;

    UPROPERTY()
    FOnButtonGroundPoundStarted OnButtonGroundPoundStarted;
    UPROPERTY()
    FOnButtonGroundPoundCompleted OnButtonGroundPoundCompleted;
    UPROPERTY()
    FOnButtonReset OnButtonReset;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonPressAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonReleaseAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonEnterSwayAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonLeaveSwayAudioEvent;

	UPROPERTY()
    float FullyPressedOffset = 115.f;

    UPROPERTY(meta = (InlineEditConditionToggle))
    bool bResetAutomatically = false;

    UPROPERTY(meta = (EditCondition = "bResetAutomatically"))
    float ResetAfterTime = 3.f;

	UPROPERTY()
	bool bStartDisabled = false;

	float LowerBound = -57.5f;

	UPROPERTY(meta = (Category = "SpringSettings"))
	float UpperBound = 0;

	UPROPERTY(meta = (Category = "SpringSettings"))
	float LowerBounciness = 0;

	UPROPERTY(meta = (Category = "SpringSettings"))
	float UpperBounciness = 1.f;

	UPROPERTY(meta = (Category = "SpringSettings"))
	float Friction = 6.5f;

	UPROPERTY(meta = (Category = "SpringSettings"))
	float SpringStrength = 150.f;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	private TArray<AHazePlayerCharacter> PlayersStandingOnButton;

	private bool bVisualStatePressed = false;
	private bool bVisualStateFullyDown = false;
	private int VisualStatePressedId = -1;
	const float PressDuration = 0.2f;

	private bool bIsDisabled = false;
	private AHazePlayerCharacter PlayerGroundPounding;
	private int ControlPressedId = -1;
	private float ControlResetTimer = -1.f;

	UPROPERTY(meta = (Category = "SpringSettings"))
	float Acceleration = 3000.f;

    UFUNCTION(BlueprintEvent)
    void BP_GroundPoundButton_Push()
    {}

    UFUNCTION(BlueprintEvent)
    void BP_GroundPoundButton_Release()
    {}

	UFUNCTION(BlueprintEvent)
    void BP_GroundPoundButton_Enter(TArray<AHazePlayerCharacter> _players)
    {}

	UFUNCTION(BlueprintEvent)
    void BP_GroundPoundButton_Leave(TArray<AHazePlayerCharacter> _players)
    {}

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ButtonMesh.SetCullDistance(Editor::GetDefaultCullingDistance(ButtonMesh) * CullDistanceMultiplier);
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"ButtonGroundPounded");

		PhysicsValue.LowerBound = -FullyPressedOffset;
		PhysicsValue.UpperBound = UpperBound;
		PhysicsValue.LowerBounciness = LowerBounciness;
		PhysicsValue.UpperBounciness = UpperBounciness;
		PhysicsValue.Friction = Friction;

		if (bStartDisabled)
		{
			bIsDisabled = true;
			DisableVisuals();
		}

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
    }

	UFUNCTION()
	void DisableButton()
	{
		if (bIsDisabled)
			return;

		if (HasControl())
			NetControlDisable();
	}

	UFUNCTION(NetFunction)
	private void NetControlDisable()
	{
		bIsDisabled = true;
		DisableVisuals();
	}

	private void DisableVisuals()
	{
		bVisualStatePressed = true;
		bVisualStateFullyDown = true;

		if (PlayerGroundPounding != nullptr)
			FinishGroundPound();

		PhysicsValue.SnapTo(-FullyPressedOffset, true);

		FVector MeshLocation = ButtonMesh.RelativeLocation;
		MeshLocation.Z = PhysicsValue.Value;
		ButtonMesh.RelativeLocation = MeshLocation;
	}

	UFUNCTION()
	void DisableAutomaticReset()
	{
		bResetAutomatically = false;
		ControlResetTimer = -1.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bContinueTicking = false;

		if (bVisualStatePressed)
		{
			if (!bVisualStateFullyDown)
			{
				// Update the button being pressed down
				bContinueTicking = true;

				PhysicsValue.Value = FMath::Max(
					-FullyPressedOffset,
					PhysicsValue.Value - (FullyPressedOffset * (DeltaTime / PressDuration))
				);

				FVector MeshLocation = ButtonMesh.RelativeLocation;
				MeshLocation.Z = PhysicsValue.Value;
				ButtonMesh.RelativeLocation = MeshLocation;

				if (PhysicsValue.Value <= -FullyPressedOffset)
				{
					bVisualStateFullyDown = true;
					if (PlayerGroundPounding != nullptr)
						FinishGroundPound();
				}
			}
		}
		else if (!bIsDisabled)
		{
			// Update the button springing up
			if (PlayersStandingOnButton.Num() == 1)
				PhysicsValue.AddAcceleration(-Acceleration);
			else if (PlayersStandingOnButton.Num() == 2)
				PhysicsValue.AddAcceleration(-Acceleration * 2);

			PhysicsValue.Update(DeltaTime);
			PhysicsValue.SpringTowards(0.f, SpringStrength);
			
			FVector MeshLocation = ButtonMesh.RelativeLocation;
			MeshLocation.Z = PhysicsValue.Value;
			ButtonMesh.RelativeLocation = MeshLocation;

			if (PlayersStandingOnButton.Num() != 0)
				bContinueTicking = true;
			if (!PhysicsValue.CanSleep(SettledTargetValue = 0.f))
				bContinueTicking = true;
		}

		if (HasControl())
		{
			if (ControlResetTimer > 0.f)
			{
				ControlResetTimer -= DeltaTime;
				bContinueTicking = true;

				if (ControlResetTimer <= 0.f)
				{
					ResetButton();
				}
			}
		}

		if (!bContinueTicking)
			SetActorTickEnabled(false);
	}

    UFUNCTION(NotBlueprintCallable)
    void ButtonGroundPounded(AHazePlayerCharacter Player)
    {
		if (!Player.HasControl())
			return;
		if (bVisualStatePressed)
			return;
		if (bIsDisabled)
			return;

		bVisualStatePressed = true;
		VisualStatePressedId = (ControlPressedId + 1);
		SetActorTickEnabled(true);

		if (HasControl())
			NetControlPounded(Player, (ControlPressedId + 1));
		else
			NetRemotePounded(Player, (ControlPressedId + 1));
	}

	UFUNCTION(NetFunction)
	private void NetRemotePounded(AHazePlayerCharacter Player, int PressedId)
	{
		if (HasControl())
		{
			// If we've already pressed it from the control side, ignore this press
			if (ControlPressedId >= PressedId)
				return;
			// If the button has already been disabled we can't pound it
			if (bIsDisabled)
				return;

			NetControlPounded(Player, PressedId);
		}
	}

	UFUNCTION(NetFunction)
	private void NetControlPounded(AHazePlayerCharacter Player, int PressedId)
	{
		bVisualStatePressed = true;
		VisualStatePressedId = PressedId;
		ControlPressedId = PressedId;

		if (HasControl())
		{
			if (bResetAutomatically)
				ControlResetTimer = ResetAfterTime;
		}

		PlayerGroundPounding = Player;
		Player.PlayerHazeAkComp.HazePostEvent(ButtonPressAudioEvent);

		OnButtonGroundPoundStarted.Broadcast(Player);
		BP_GroundPoundButton_Push();

		if (bVisualStateFullyDown)
			FinishGroundPound();

		SetActorTickEnabled(true);
	}

	private void FinishGroundPound()
	{
		OnButtonGroundPoundCompleted.Broadcast(PlayerGroundPounding);
		PlayerGroundPounding = nullptr;
	}

    UFUNCTION()
    void ResetButton()
    {
		if (!HasControl())
			return;
		if (!bVisualStatePressed)
			return;

		NetControlReset(ControlPressedId);
	}

	UFUNCTION(NetFunction)
	private void NetControlReset(int PressedId)
	{
		devEnsure(PressedId >= VisualStatePressedId, "GroundPoundButton Reset Desync");

		if (PlayerGroundPounding != nullptr)
			FinishGroundPound();

		bIsDisabled = false;
		bVisualStatePressed = false;
		bVisualStateFullyDown = false;
		PhysicsValue.Value = -FullyPressedOffset;
		PhysicsValue.SnapVelocityTo(1.f);

		SetActorTickEnabled(true);
		UHazeAkComponent::HazePostEventFireForget(ButtonReleaseAudioEvent, this.GetActorTransform());

        BP_GroundPoundButton_Release();
		OnButtonReset.Broadcast();
	}

	UFUNCTION(BlueprintPure)
	bool IsButtonGroundPounded()
	{
		return bVisualStateFullyDown;
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		PlayersStandingOnButton.Add(Player);
		if (PlayersStandingOnButton.Num() == 1)
			EnteredButton(Player);

		if (!bVisualStateFullyDown && (PlayersStandingOnButton.Num() == 1))
			Player.PlayerHazeAkComp.HazePostEvent(ButtonEnterSwayAudioEvent);

		BP_GroundPoundButton_Enter(PlayersStandingOnButton);
		SetActorTickEnabled(true);
	}


	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		PlayersStandingOnButton.Remove(Player);
		if (PlayersStandingOnButton.Num() == 0)
			LeftButton();

		if (!bVisualStateFullyDown && (PlayersStandingOnButton.Num() == 0))
			Player.PlayerHazeAkComp.HazePostEvent(ButtonLeaveSwayAudioEvent);

		BP_GroundPoundButton_Leave(PlayersStandingOnButton);
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintEvent)
	void EnteredButton(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void LeftButton() {}
}