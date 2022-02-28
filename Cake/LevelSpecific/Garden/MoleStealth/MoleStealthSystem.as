import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSettings;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSettingsSoundIncreaseWithBush;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSettingsSoundIncrease;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSettingsSoundDecrease;
import Vino.PlayerHealth.PlayerHealthComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseProjectile;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.Capabilities.Sprint.CharacterSprintComponent;
import Cake.LevelSpecific.Garden.Vine.VineComponent;

// EVENTS
delegate void FMoleStealthShapeActivationEvent(AMoleStealthShape Shape, AHazePlayerCharacter ByPlayer);
delegate void FMoleStealthShapeDeactivationEvent(AMoleStealthShape Shape, AHazePlayerCharacter ByPlayer);

event void FMoleStealthDetectedEvent(AMoleStealthManager Manager);
event void FMoleStealthCriticalAmountEvent(bool bCodyIsABush, bool bMayIsInsideBush);
event void FMoleStealthKilledByMole(bool RolledOver, float Delay);

// WIDGET
UCLASS(Abstract)
class UMoleStealthDetectionWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	float DetectionAmountAlpha = 0;

	UPROPERTY(BlueprintReadOnly)
	float DetectionAmountSecondLifeAlpha = 0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve ActiveTimeToAlphaCurve;

	float ActiveTime = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		ActiveTime += InDeltaTime;
	}

	UFUNCTION(BlueprintPure)
	float GetActivationAlpha()const
	{
		return ActiveTimeToAlphaCurve.GetFloatValue(ActiveTime);
	}

	UFUNCTION(BlueprintEvent)
	void Initalize()
	{
		Log("Blueprint did not override this event.");
	}

	UFUNCTION(BlueprintEvent)
	void ChangeVisibility(ESlateVisibility NewStatus, float Delay)
	{
		ActiveTime = -Delay;
	}
}

// SHAPE
UCLASS(NotPlaceable, NotBlueprintable)
class AMoleStealthShape : AVolume
{
	default SetActorTickEnabled(false);
	default BrushComponent.SetCollisionProfileName(n"Trigger");
	default bGenerateOverlapEventsDuringLevelStreaming = true;

	UPROPERTY(Category = "Stealth")
	AMoleStealthManager Manager;

	bool bHasSetupOnBothSides = false;

	UPROPERTY()
	FMoleStealthShapeActivationEvent OnActivated;

	UPROPERTY()
	FMoleStealthShapeActivationEvent OnDeactivated;

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr && Player.HasControl() && bHasSetupOnBothSides)
		{
			Manager.NetAddPlayer(Player, this);
		}
	}

	UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr && Player.HasControl() && bHasSetupOnBothSides)
		{
			Manager.NetRemovePlayer(Player, this);
		}
	}

	void TriggerBeginPlay()
	{
		bHasSetupOnBothSides = true;
		TArray<AActor> OverlappingActors;
		GetOverlappingActors(OverlappingActors, AHazePlayerCharacter::StaticClass());
		for(AActor OverlappingActor : OverlappingActors)
		{
			ActorBeginOverlap(OverlappingActor);
		}
	}
}

// A player inside this shape will make noice
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Replication")
class AMoleStealthNoiseShape : AMoleStealthShape
{
	UPROPERTY(EditInstanceOnly, Category = "Stealth")
	EMoleStealthDetectionSoundVolume Volume = EMoleStealthDetectionSoundVolume::Normal;	
}

// A player inside this shape will make noice
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Replication")
class AMoleStealthActivationShape : AMoleStealthShape
{

}

// A player inside this shape will make noice
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Replication")
class AMoleStealthSoundMultiplier : AHazeActor
{
	UPROPERTY(DefaultComponent)
    USphereComponent PlayerTrigger;
	default PlayerTrigger.CollisionProfileName = n"Trigger";
	default PlayerTrigger.SphereRadius = 300;

	UPROPERTY(Category = "Stealth")
	FRuntimeFloatCurve MultiplierCurve;

	UPROPERTY(Category = "Stealth")
	AMoleStealthManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		PlayerTrigger.OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		devEnsure(Manager != nullptr);

		if(Player.IsCody())
		{
			Manager.CodyMultipliers.Add(this);
		}	
		else
		{
			Manager.MayMultipliers.Add(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
    void ExitTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		devEnsure(Manager != nullptr);

		if(Player.IsCody())
		{
			Manager.CodyMultipliers.Remove(this);
		}	
		else
		{
			Manager.MayMultipliers.Remove(this);
		}
	}
}



UCLASS(NotPlaceable, NotBlueprintable)
class UMoleStealthPlayerComponent : UActorComponent
{
	default SetTickGroup(ETickingGroup::TG_HazeGameplay);

	UPROPERTY(Transient)
	UMoleStealthDetectionWidget ActiveWidget;

	AMoleStealthManager CurrentManager;

	int IsInsideGroundPoundableAreaCount = 0;
	bool bCanGroundpoundIntoBush = false;
	
	bool bCodyIsABush = false;
	bool bMayIsInsideCodysBush = false;
	private FVector BushLocation;

	int WidgetVisiblityChangeStatus = 0;
	float ShowWidgetDelay = 0;
	EHazePlayer LastPlayerIncreasedSound = EHazePlayer::MAX;

	void ActivateBush()
	{
		bCodyIsABush = true;
	}

	void DeactivateBush()
	{
		bCodyIsABush = false;
	}

	bool BushIsActive() const
	{
		return bCodyIsABush;
	}

	void SetMayInsideBush(bool bStatus)
	{
		bMayIsInsideCodysBush = bStatus;
		const EHazeActionState ActionStatus = bStatus ? EHazeActionState::Active : EHazeActionState::Inactive;
		Game::GetMay().SetCapabilityActionState(n"IsInsideSneakyBush", ActionStatus);
	}

	void UpdateBushLocation(FVector Location)
	{
		BushLocation = Location;
	}

	void UpdateWidgetValues()
	{
		if(ActiveWidget != nullptr && CurrentManager != nullptr)
		{
			ActiveWidget.DetectionAmountAlpha = CurrentManager.CurrentVolume / MoleStealthSettings::MaxVolume;
			ActiveWidget.DetectionAmountSecondLifeAlpha = CurrentManager.CurrentSecondLifeVolume / MoleStealthSettings::MaxVolumeSecondLife;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if(ActiveWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(ActiveWidget);
			ActiveWidget = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if(CurrentManager != nullptr)
			CurrentManager.UpdateValues(DeltaTime);

		if(WidgetVisiblityChangeStatus != 0)
		{
			UpdateWidgetVisibilityChange();
		}

		UpdateWidgetValues();
	}

	void UpdateWidgetVisibilityChange()
	{
		if(ActiveWidget != nullptr)
		{
			if(WidgetVisiblityChangeStatus == 1)
			{
				ActiveWidget.ChangeVisibility(ESlateVisibility::Visible, ShowWidgetDelay);
			}
			else if(WidgetVisiblityChangeStatus == -1)
			{
				ActiveWidget.ChangeVisibility(ESlateVisibility::Hidden, 0.f);
			}
			WidgetVisiblityChangeStatus = 0;
		}	
	}
}

// MANAGER
UCLASS(Abstract)
class AMoleStealthManager : AHazeActor
{
	default SetTickGroup(ETickingGroup::TG_PostPhysics);

	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = "Billboard")
	UTextRenderComponent ManagerText;
	default ManagerText.SetRelativeLocation(FVector(0, 0, 50.f));
	default ManagerText.SetText(FText::FromString("Mole Stealth Manager"));
	default ManagerText.SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
	default ManagerText.SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
	default ManagerText.SetHiddenInGame(true);
	default ManagerText.XScale = 5;
	default ManagerText.YScale = 5;

	// Since may is the deciding side of the gameover, this also needs to go trough that.
	UPROPERTY(DefaultComponent)
	UHazeNetworkControlSideInitializeComponent ControlSideComponent;
	default ControlSideComponent.ControlSide = EHazePlayer::May; 

	UPROPERTY(EditDefaultsOnly, Category = "Stealth")
    TSubclassOf<UMoleStealthDetectionWidget> DetectionWidget;
	
	UPROPERTY(Category = "Stealth")
	UHazeCapabilitySheet PlayerSheet;

	UPROPERTY(EditConst, Category = "Stealth")
	TArray<AMoleStealthActivationShape> ActivationShapes;

	UPROPERTY(EditConst, Category = "Stealth")
	TArray<AMoleStealthNoiseShape> NoiseShapes;

	UPROPERTY(EditConst, Category = "Stealth")
	TArray<AMoleStealthSoundMultiplier> LevelSoundMultipliers;

	UPROPERTY(Category = "Events")
	FMoleStealthDetectedEvent OnDetected;

	UPROPERTY(Category = "Events")
	FMoleStealthCriticalAmountEvent OnCriticalTriggered;

	UPROPERTY(Category = "Events")
    FMoleStealthKilledByMole OnKilledByMole;

	TArray<EMoleStealthDetectionSoundVolume> CodyActiveNoiseAmounts;
	TArray<EMoleStealthDetectionSoundVolume> MayActiveNoiseAmounts;

	bool bHasBeenDetected = false;
		
	private TPerPlayer<bool> bWaitingDetectionValidation;
	private TPerPlayer<bool> bBlockCanDie;
	private TPerPlayer<bool> bKilledByMole;
	float TimeToResendRequest = 0;

	private float TimeLeftToDecreaseSound = 0;
	float CurrentVolume = 0;
	float CurrentSecondLifeVolume = 0;
	private bool bHasIncreasedFinalTimeThisFrame = false;

	TPerPlayer<float> LastIncreaseAmount;
	TArray<AMoleStealthSoundMultiplier> CodyMultipliers;
	TArray<AMoleStealthSoundMultiplier> MayMultipliers;

	private int CodyActiveShapeCounter = 0;
	private int MayActiveShapeCounter = 0;
	private int FrameCount = 0;

	TPerPlayer<int> NetworkIndex;
	TPerPlayer<uint> LastIncreaseFrameCount;
	TPerPlayer<bool> bIncreasingSound;

	TPerPlayer<bool> bPlayerHasInitialized;

	UFUNCTION()
	void ResetDetectionAmount()
	{
		bHasBeenDetected = false;
		ResetVolume();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		OnDetected.Clear();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{	
		for(auto ActivationShape : ActivationShapes)
		{
			ActivationShape.OnActivated.Clear();
			ActivationShape.OnDeactivated.Clear();
		}
					
		for(auto NoiseShape : NoiseShapes)
		{
			NoiseShape.OnActivated.Clear();
			NoiseShape.OnDeactivated.Clear();
		}

		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
		if(ManagerComponent != nullptr)
			ManagerComponent.CurrentManager	= nullptr;

		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			Player.RemoveCapabilitySheet(PlayerSheet, this);

			if(bBlockCanDie[Player.Player])
			{
				RemovePlayerInvulnerability(Player, this);
				bBlockCanDie[Player.Player] = false;
			}

			if(bKilledByMole[Player.Player])
			{
				Player.UnblockCapabilities(n"Respawn", this);
				bKilledByMole[Player.Player] = false;
			}
		}

		LastIncreaseAmount[0] = 0;
		bIncreasingSound[0] = false;
		
		LastIncreaseAmount[1] = 0;
		bIncreasingSound[1] = false;

		auto WaterComponent = UWaterHoseComponent::Get(Game::GetMay());
		if(WaterComponent != nullptr)
			WaterComponent.OnWaterProjectileStealthZoneImpact.Clear();

		auto VineComponent = UVineComponent::Get(Game::GetCody());
		if(VineComponent != nullptr)
			VineComponent.OnStartRetractingEvent.UnbindObject(this);
	}

	UFUNCTION()
	void InitializeStealth()
	{	
		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			Player.AddCapabilitySheet(PlayerSheet, EHazeCapabilitySheetPriority::Level, this);

			if(Player.HasControl())
			{
				FHazeCrumbDelegate Delegate;
				Delegate.BindUFunction(this, n"Crumb_InitializeStealthForPlayer");
				
				FHazeDelegateCrumbParams Params;
				Params.AddNumber(n"Player", Player.Player);
				UHazeCrumbComponent::Get(Player).LeaveAndTriggerDelegateCrumb(Delegate, Params);
			}
		}

		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
		ManagerComponent.CurrentManager	= this;

		auto WaterComponent = UWaterHoseComponent::Get(Game::GetMay());
		WaterComponent.OnWaterProjectileStealthZoneImpact.Clear();
		WaterComponent.OnWaterProjectileStealthZoneImpact.AddUFunction(this, n"OnWaterProjectileImpact");

		auto VineComponent = UVineComponent::Get(Game::GetCody());
		VineComponent.OnStartRetractingEvent.AddUFunction(this, n"OnVineImpact");	

		Sync::FullSyncPoint(this, n"InitializeShapes");
	}

	UFUNCTION(NotBlueprintCallable)
	void InitializeShapes()
	{
		for(AMoleStealthActivationShape Shape : ActivationShapes)
		{
			Shape.OnActivated.BindUFunction(this, n"MainShapeActivated");
			Shape.OnDeactivated.BindUFunction(this, n"MainShapeDeactivated");
			Shape.TriggerBeginPlay();
		}

		for(AMoleStealthNoiseShape Shape : NoiseShapes)
		{
			Shape.OnActivated.BindUFunction(this, n"SoundShapeActivated");
			Shape.OnDeactivated.BindUFunction(this, n"SoundShapeDeactivated");
			Shape.TriggerBeginPlay();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_InitializeStealthForPlayer(FHazeDelegateCrumbData Data)
	{
		EHazePlayer PlayerIndex = EHazePlayer(Data.GetNumber(n"Player"));
		bPlayerHasInitialized[PlayerIndex] = true;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetAddPlayer(AHazePlayerCharacter Player, AMoleStealthShape Shape)
	{
		if(Player != nullptr && Shape != nullptr)
			Shape.OnActivated.ExecuteIfBound(Shape, Player);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetRemovePlayer(AHazePlayerCharacter Player, AMoleStealthShape Shape)
	{
		if(Player != nullptr && Shape != nullptr)
			Shape.OnDeactivated.ExecuteIfBound(Shape, Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnWaterProjectileImpact(AWaterHoseProjectile Projectile, FHitResult Impact)
	{
		if(!Impact.bBlockingHit)
			return;

		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
		if(ManagerComponent.CurrentManager.MayActiveShapeCounter <= 0)
			return;

		// USE THIS TO HAVE WATER DO NOICE EVERYWHERE
		float Amount = MoleStealthSettings::GetWaterImpactVolumeIncreaseAmount(EMoleStealthDetectionSoundVolume::Normal);
		IncreaseSoundAmountManually(Amount);
		
		// USE THIS TO HAVE WATER ONLY DO NOICE INSIDE SHAPES
		// for(auto NoiseShape : NoiseShapes)
		// {
		// 	if(NoiseShape.GetDistanceTo(Impact.Location) < 1)
		// 	{
		// 		float Amount = MoleStealthSettings::GetWaterImpactVolumeIncreaseAmount(NoiseShape.Volume);
		// 		IncreaseSoundAmountManually(Amount);
		// 		return;
		// 	}
		// }	
	}

	UFUNCTION(NotBlueprintCallable)
	void OnVineImpact(FVineHitResult Impact)
	{
		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
		if(ManagerComponent.CurrentManager.CodyActiveShapeCounter <= 0)
			return;

		float Amount = MoleStealthSettings::GetVineImpactVolumeIncreaseAmount(Impact.bBlockingHit);
		IncreaseSoundAmountManually(Amount);
	}

	UFUNCTION(CallInEditor, Category = "Stealth")
	void CollectShapes()
	{
		TArray<AActor> FoundActivationShapes;
		Gameplay::GetAllActorsOfClass(AMoleStealthActivationShape::StaticClass(), FoundActivationShapes);
		ActivationShapes.Empty(FoundActivationShapes.Num());

		TArray<AActor> FoundNoiseShapes;
		Gameplay::GetAllActorsOfClass(AMoleStealthNoiseShape::StaticClass(), FoundNoiseShapes);
		NoiseShapes.Empty(FoundNoiseShapes.Num());
		
		for(int i = 0; i < FoundActivationShapes.Num(); ++i)
		{
			auto ActivationShape = Cast<AMoleStealthActivationShape>(FoundActivationShapes[i]);
			ActivationShapes.Add(ActivationShape);
		}

		for(int i = 0; i < FoundNoiseShapes.Num(); ++i)
		{
			auto NoiseShape = Cast<AMoleStealthNoiseShape>(FoundNoiseShapes[i]);
			NoiseShapes.Add(NoiseShape);
		}
	}

	UFUNCTION(CallInEditor, Category = "Stealth")
	void CollectSoundMultipliers()
	{
		TArray<AActor> FoundSoundMultipliers;
		Gameplay::GetAllActorsOfClass(AMoleStealthSoundMultiplier::StaticClass(), FoundSoundMultipliers);
		LevelSoundMultipliers.Empty(FoundSoundMultipliers.Num());
		for(auto SoundMultiplierActor : FoundSoundMultipliers)
		{
			AMoleStealthSoundMultiplier SoundMultiplier = Cast<AMoleStealthSoundMultiplier>(SoundMultiplierActor);
			SoundMultiplier.Manager = this;
			LevelSoundMultipliers.Add(SoundMultiplier);
		}
	}

	UFUNCTION(CallInEditor, Category = "Stealth")
	void FixupShapeRefs()
	{
		for(auto Shape : ActivationShapes)
		{
			if(Shape == nullptr)
				continue;

			Shape.Manager = this;
		}

			
		for(auto Shape : NoiseShapes)
		{
			if(Shape == nullptr)
				continue;

			Shape.Manager = this;
		}		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		const bool bHasControl = HasControl();

		// When starting from a checkpoint, we need a few frames to make the players grounded before we start ticking
		FrameCount++;
		if(FrameCount < 10)
			return;

		if(WaitingDetectionValidation)
			return;

		if(bHasBeenDetected)
			return;

		// Increase codys sound
		const EMoleStealthDetectionSoundVolume CodySoundType = GetCodyDetectionSoundType();

		//PrintToScreen("Cody: " + CodyActiveNoiseAmounts.Num() + " Type: " + CodySoundType);
		IncreaseCodyVolume(CodySoundType, DeltaTime);
	
		// Increase mays sound
		EMoleStealthDetectionSoundVolume MaySoundType = GetMayDetectionSoundType();

		//PrintToScreen("May: " + MayActiveNoiseAmounts.Num() + " Type: " + MaySoundType);
		IncreaseMayVolume(MaySoundType, DeltaTime);

		// Validation on the other side if we have been detected
		if(!bHasBeenDetected)
		{
			TimeToResendRequest = FMath::Max(TimeToResendRequest - DeltaTime, 0.f);

			if(TimeToResendRequest <= 0)
			{
				if(ShouldBeDetected())
				{
					auto Players = Game::GetPlayers();
					for(auto Player : Players)
					{
						if(!Player.HasControl())
							continue;

						// We send over from the players side that we have been detected.
						// In local gameplay, this is made 2 times but its a nice validation
						// That we can handle messages coming in at the same time
						NetSendDetectionValidationRequest(Player);
					}

					TimeToResendRequest = 2.f;	
				}
			}
		}
	}

	EMoleStealthDetectionSoundVolume GetCodyDetectionSoundType() const
	{
		EMoleStealthDetectionSoundVolume CodySoundType = EMoleStealthDetectionSoundVolume::Null;
		if(CodyActiveShapeCounter > 0)
			CodySoundType = EMoleStealthDetectionSoundVolume::None;

		for(int i = 0; i < CodyActiveNoiseAmounts.Num(); ++i)
		{
			if(int(CodyActiveNoiseAmounts[i]) > int(CodySoundType))
			{
				CodySoundType = CodyActiveNoiseAmounts[i];
			}
		}

		return CodySoundType;
	}

	EMoleStealthDetectionSoundVolume GetMayDetectionSoundType() const
	{
		EMoleStealthDetectionSoundVolume MaySoundType = EMoleStealthDetectionSoundVolume::Null;
		if(MayActiveShapeCounter > 0)
			MaySoundType = EMoleStealthDetectionSoundVolume::None;

		for(int i = 0; i < MayActiveNoiseAmounts.Num(); ++i)
		{
			if(int(MayActiveNoiseAmounts[i]) > int(MaySoundType))
			{
				MaySoundType = MayActiveNoiseAmounts[i];
			}
		}

		return MaySoundType;
	}

	bool GetWaitingDetectionValidation() const property
	{
		return bWaitingDetectionValidation[0] || bWaitingDetectionValidation[1];
	}

	bool ShouldBeDetected() const
	{
		if(bKilledByMole[0] || bKilledByMole[1])
			return false;
		
		if(IAnyPlayerDead())
			return false;

		if(bHasBeenDetected)
			return false;

		if(!PlayersAreDetected())
			return false;

		return true;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
    void NetSendDetectionValidationRequest(AHazePlayerCharacter RequestingPlayer)
    {
		bWaitingDetectionValidation[RequestingPlayer.Player] = true;

		AddPlayerInvulnerability(RequestingPlayer, this);
		bBlockCanDie[RequestingPlayer.Player] = true;
	
		// Finish on the other players side
		if(RequestingPlayer.GetOtherPlayer().HasControl())
		{
			NetSendDetectionValidationResponse(RequestingPlayer, ShouldBeDetected());
		}
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
    void NetSendDetectionValidationResponse(AHazePlayerCharacter RequestingPlayer, bool bStatus)
    {
		bWaitingDetectionValidation[RequestingPlayer.Player] = false;
		if(bStatus && !bHasBeenDetected)
		{
			bHasBeenDetected = true;
			OnDetected.Broadcast(this);
		}
		else if(bBlockCanDie[RequestingPlayer.Player])
		{
			RemovePlayerInvulnerability(RequestingPlayer, this);
			bBlockCanDie[RequestingPlayer.Player] = false;
		}
    }

	void KilledByMole(AHazePlayerCharacter Player, bool bRolledOver, float Delay)
	{
		if(bKilledByMole[Player.Player])
			return;

		if(bHasBeenDetected)
			return;

		bKilledByMole[Player.Player] = true;
		Player.BlockCapabilities(n"Respawn", this);
		bHasBeenDetected = true;

		// We validate on the same side as the gameover is validated
		if(!Game::GetMay().HasControl())
			return;

		NetSendKilledByMole(Player, bRolledOver, Delay);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
    void NetSendKilledByMole(AHazePlayerCharacter Player, bool bRolledOver, float Delay)
	{
		bHasBeenDetected = true;
		if(!bKilledByMole[Player.Player])
		{
			bKilledByMole[Player.Player] = true;
			Player.BlockCapabilities(n"Respawn", this);
		}
	
		OnKilledByMole.Broadcast(bRolledOver, Delay);
	}

	void UpdateValues(float DeltaTime)
	{
		// Stealth manager is locked until we have the acc
		if(WaitingDetectionValidation)
			return;

		if(bHasBeenDetected)
			return;

		TimeLeftToDecreaseSound -= DeltaTime;
		if(TimeLeftToDecreaseSound <= 0)
		{
			CurrentSecondLifeVolume = 0.f;
			CurrentVolume = FMath::FInterpConstantTo(CurrentVolume, 0.f, DeltaTime, MoleStealthSettings::DecreaseSpeed);		
		}

		bHasIncreasedFinalTimeThisFrame = false;

		if(Game::GetMay().HasControl()
			&& bIncreasingSound[EHazePlayer::May]
			&& Time::GetFrameNumber() > LastIncreaseFrameCount[EHazePlayer::May] + 10)
		{
			NetSetIncreasingSound(NetworkIndex[EHazePlayer::May] + 1, EHazePlayer::May, false);
		}

		if(!bIncreasingSound[EHazePlayer::May])
			LastIncreaseAmount[EHazePlayer::May] = 0;

		if(Game::GetCody().HasControl()
			&& bIncreasingSound[EHazePlayer::Cody]
			&& Time::GetFrameNumber() > LastIncreaseFrameCount[EHazePlayer::Cody] + 10)
		{
			NetSetIncreasingSound(NetworkIndex[EHazePlayer::Cody] + 1, EHazePlayer::Cody, false);
		}

		if(!bIncreasingSound[EHazePlayer::Cody])
			LastIncreaseAmount[EHazePlayer::Cody] = 0;
	}

	float DecreaseTimeCooldown() const
	{
		return TimeLeftToDecreaseSound;
	}

	UFUNCTION(NotBlueprintCallable)
	void MainShapeActivated(AMoleStealthShape Shape, AHazePlayerCharacter ByPlayer)
	{
		if(ByPlayer.IsCody())
		{
			CodyActiveShapeCounter++;
			if(CodyActiveShapeCounter == 1)
				ByPlayer.SetCapabilityActionState(n"MoleStealthActive", EHazeActionState::Active);
		}
		else
		{
			MayActiveShapeCounter++;
			if(MayActiveShapeCounter == 1)
				ByPlayer.SetCapabilityActionState(n"MoleStealthActive", EHazeActionState::Active);
		}

		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());	
		if(ManagerComponent != nullptr)
		{
			if(ActiveShapeCounter == 1)
			{
				ManagerComponent.ActiveWidget = Cast<UMoleStealthDetectionWidget>(Widget::AddFullscreenWidget(DetectionWidget.Get()));
				ManagerComponent.ActiveWidget.SetWidgetPersistent(true);
				ManagerComponent.ActiveWidget.Initalize();
				ManagerComponent.UpdateWidgetValues();
				SetActorTickEnabled(true);
				AkGameplay::SetState(n"StateGroup_Gameplay", n"Stt_Gameplay_Stealth");
				//Print("Stt_Gameplay_Stealth");
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void MainShapeDeactivated(AMoleStealthShape Shape, AHazePlayerCharacter ByPlayer)
	{
		if(ByPlayer.IsCody())
		{
			CodyActiveShapeCounter--;
			if(CodyActiveShapeCounter == 0)
				ByPlayer.SetCapabilityActionState(n"MoleStealthActive", EHazeActionState::Inactive);
		}
		else
		{
			MayActiveShapeCounter--;
			if(MayActiveShapeCounter == 0)
				ByPlayer.SetCapabilityActionState(n"MoleStealthActive", EHazeActionState::Inactive);
		}

		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
		if(ManagerComponent != nullptr)
		{
			if(ActiveShapeCounter == 0)
			{
				if(ManagerComponent.ActiveWidget != nullptr)
				{
					Widget::RemoveFullscreenWidget(ManagerComponent.ActiveWidget);
					ManagerComponent.ActiveWidget = nullptr;
				}
					
				SetActorTickEnabled(false);
				AkGameplay::SetState(n"StateGroup_Gameplay", n"Stt_Gameplay_Default");
				//Print("Stt_Gameplay_Default");
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void SoundShapeActivated(AMoleStealthShape Shape, AHazePlayerCharacter ByPlayer)
	{
		auto NoiseShape = Cast<AMoleStealthNoiseShape>(Shape);
		if(NoiseShape != nullptr)
		{
			if(ByPlayer.IsCody())
			{
				CodyActiveNoiseAmounts.Add(NoiseShape.Volume);
				if(CodyActiveNoiseAmounts.Num() == 1)
					ByPlayer.SetCapabilityActionState(n"MoleStealthNoiseShapeActive", EHazeActionState::Active);
			}
			else
			{
				MayActiveNoiseAmounts.Add(NoiseShape.Volume);
				if(MayActiveNoiseAmounts.Num() == 1)
					ByPlayer.SetCapabilityActionState(n"MoleStealthNoiseShapeActive", EHazeActionState::Active);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void SoundShapeDeactivated(AMoleStealthShape Shape, AHazePlayerCharacter ByPlayer)
	{
		auto NoiseShape = Cast<AMoleStealthNoiseShape>(Shape);
		if(NoiseShape != nullptr)
		{
			if(ByPlayer.IsCody())
			{
				CodyActiveNoiseAmounts.Remove(NoiseShape.Volume);
				if(CodyActiveNoiseAmounts.Num() == 0)
					ByPlayer.SetCapabilityActionState(n"MoleStealthNoiseShapeActive", EHazeActionState::Inactive);
			}
			else
			{
				MayActiveNoiseAmounts.Remove(NoiseShape.Volume);
				if(MayActiveNoiseAmounts.Num() == 0)
					ByPlayer.SetCapabilityActionState(n"MoleStealthNoiseShapeActive", EHazeActionState::Inactive);
			}
		}
	}
	
	UFUNCTION()
	void IncreaseSoundAmountManually(float Amount, bool bCanEffectSecondLifeAmount = true)
	{
		if(Amount <= 0)
			return;

		IncreaseVolume(Amount, bCanEffectSecondLifeAmount);
		if(CurrentVolume < MoleStealthSettings::MaxVolume)
			TimeLeftToDecreaseSound = MoleStealthSettings::TimeUntilDecreaseStarts;
		else
			TimeLeftToDecreaseSound = MoleStealthSettings::TimeUntilDecreaseStartsSecondLife;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentSoundAmount(bool bIncludeSecondLifeAmount = true)const
	{
		float CurrentTotalVolume = 0;
		float SecondLifeVolume = 0;
		GetVolume(CurrentTotalVolume, SecondLifeVolume);
		if(bIncludeSecondLifeAmount)
			CurrentTotalVolume += SecondLifeVolume;
		return CurrentTotalVolume;
	}

	int GetActiveShapeCounter()const property
	{
		return CodyActiveShapeCounter + MayActiveShapeCounter;
	}

	int GetActiveShapeCounter(EHazePlayer ForPlayer)const
	{
		if(ForPlayer == EHazePlayer::May)
			return MayActiveShapeCounter;
		else
			return CodyActiveShapeCounter;
	}

	void IncreaseCodyVolume(EMoleStealthDetectionSoundVolume SoundType, float DeltaTime)
	{
		auto Player = Game::GetCody();
		if(!Player.HasControl())
			return;

		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Player);
		if(ManagerComponent == nullptr)
			return;

		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
		if(HealthComp != nullptr && HealthComp.GodMode == EGodMode::God)
			return;

		if(HealthComp.GodMode == EGodMode::Jesus && CurrentVolume >= MoleStealthSettings::MaxVolume)
			return;

		if(SoundType == EMoleStealthDetectionSoundVolume::InstantDeath && HealthComp.GodMode != EGodMode::Mortal)
			return;
			
		float FinalAmount = 0;

		if(ManagerComponent.bCodyIsABush)
			FinalAmount = MoleStealthBushSettings::GetVolumeIncreaseAmount(SoundType, DeltaTime, Player);
		else 
			FinalAmount = MoleStealthSettings::GetVolumeIncreaseAmount(SoundType, DeltaTime, Player);

		FinalAmount *= GetMultiplierValue(Player.GetActorLocation(), CodyMultipliers);

		if(FinalAmount <= KINDA_SMALL_NUMBER)
			return;

		UpdateCurrentVolume(EHazePlayer::Cody, SoundType, FinalAmount);
		
		if(!bIncreasingSound[EHazePlayer::Cody])
			NetSetIncreasingSound(NetworkIndex[EHazePlayer::Cody] + 1, EHazePlayer::Cody, true);

		NetIncreaseVolume(NetworkIndex[EHazePlayer::Cody], EHazePlayer::Cody, SoundType, CurrentVolume, CurrentSecondLifeVolume);
	}

	void IncreaseMayVolume(EMoleStealthDetectionSoundVolume SoundType, float DeltaTime)
	{
		auto Player = Game::GetMay();
		if(!Player.HasControl())
			return;

		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
		if(ManagerComponent == nullptr)
			return;

		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
		if(HealthComp.GodMode == EGodMode::God)
			return;

		if(HealthComp.GodMode == EGodMode::Jesus && CurrentVolume >= MoleStealthSettings::MaxVolume)
			return;

		bool bIsSprinting = false;
		UCharacterSprintComponent SprintComp = UCharacterSprintComponent::Get(Player);
		if(SprintComp != nullptr)
			bIsSprinting = SprintComp.bSprintActive;
		
		float FinalAmount = 0;
		if(ManagerComponent.bMayIsInsideCodysBush && !bIsSprinting)
			FinalAmount = MoleStealthBushSettings::GetVolumeIncreaseAmount(SoundType, DeltaTime, Player);
		else 
			FinalAmount = MoleStealthSettings::GetVolumeIncreaseAmount(SoundType, DeltaTime, Player);

		FinalAmount *= GetMultiplierValue(Player.GetActorLocation(), MayMultipliers);

		if(FinalAmount <= KINDA_SMALL_NUMBER)
			return;

		UpdateCurrentVolume(EHazePlayer::May, SoundType, FinalAmount);
		
		if(!bIncreasingSound[EHazePlayer::May])
			NetSetIncreasingSound(NetworkIndex[EHazePlayer::May] + 1, EHazePlayer::May, true);
		
		NetIncreaseVolume(NetworkIndex[EHazePlayer::May], EHazePlayer::May, SoundType, CurrentVolume, CurrentSecondLifeVolume);
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetIncreaseVolume(int NetTag, EHazePlayer Player, EMoleStealthDetectionSoundVolume SoundType, float TargetVolume, float TargetSecondLifeVolume)
	{
		if(NetTag != NetworkIndex[Player])
			return;

		NetworkIndex[Player] = NetTag;

		if(Game::GetPlayer(Player).HasControl())
			return;

		float Amount = 0;
		Amount += FMath::Max(TargetVolume - CurrentVolume, 0.f);
		Amount += FMath::Max(TargetSecondLifeVolume - CurrentSecondLifeVolume, 0.f) ;

		UpdateCurrentVolume(Player, SoundType, Amount);
	}

	UFUNCTION(NetFunction)
	void NetSetIncreasingSound(int NewNetTag, EHazePlayer Player, bool bStatus)
	{
		NetworkIndex[Player] = NewNetTag;
		bIncreasingSound[Player] = bStatus;	
		LastIncreaseFrameCount[Player] = Time::GetFrameNumber();
	}

	bool CanIncreaseSound() const
	{
		return bPlayerHasInitialized[0] && bPlayerHasInitialized[1];
	}

	void IncreaseVolume(float Amount, bool bCanAffectSecondLifeAmount)
	{
		if(!CanIncreaseSound())
			return;

		const float OldVol = CurrentVolume;

		if(CurrentVolume < MoleStealthSettings::MaxVolume)
			CurrentVolume = FMath::Min(CurrentVolume + Amount, MoleStealthSettings::MaxVolume);

		float AmountLeftToAdd = Amount;
		AmountLeftToAdd -= CurrentVolume - OldVol; 
			
		if(bCanAffectSecondLifeAmount && AmountLeftToAdd > 0)
		{
			CurrentSecondLifeVolume = FMath::Min(CurrentSecondLifeVolume + AmountLeftToAdd, MoleStealthSettings::MaxVolumeSecondLife);
		}

		if(OldVol < MoleStealthSettings::MaxVolume && CurrentVolume >= MoleStealthSettings::MaxVolume)
		{
			auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
			if(ManagerComponent != nullptr)
				OnCriticalTriggered.Broadcast(ManagerComponent.bCodyIsABush, ManagerComponent.bCodyIsABush && ManagerComponent.bMayIsInsideCodysBush);
		}
	}

	private void UpdateCurrentVolume(EHazePlayer Player, EMoleStealthDetectionSoundVolume SoundType, float Amount)
	{
		if(!CanIncreaseSound())
			return;

		if(Amount > 0)
		{
			LastIncreaseAmount[Player] = Amount;
			auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
			if(ManagerComponent != nullptr)
				ManagerComponent.LastPlayerIncreasedSound = Player;
		}

		IncreaseVolume(Amount, true);

		if(SoundType == EMoleStealthDetectionSoundVolume::InstantDeath)
		{
			CurrentVolume = MoleStealthSettings::MaxVolume;
			CurrentSecondLifeVolume = MoleStealthSettings::MaxVolume;
		}

		if(MoleStealthSettings::DelaySoundDecrease(Amount, SoundType))
		{
			if(CurrentVolume < MoleStealthSettings::MaxVolume)
				TimeLeftToDecreaseSound = MoleStealthSettings::TimeUntilDecreaseStarts;
			else
				TimeLeftToDecreaseSound = MoleStealthSettings::TimeUntilDecreaseStartsSecondLife;

			if(!bHasIncreasedFinalTimeThisFrame && CurrentVolume + CurrentSecondLifeVolume >= MoleStealthSettings::MaxVolume + MoleStealthSettings::MaxVolumeSecondLife)
			{
				bHasIncreasedFinalTimeThisFrame = true;
			}
		}
	}

	private float GetMultiplierValue(FVector PlayerLocation, const TArray<AMoleStealthSoundMultiplier>& Multipliers)const
	{
		float FinalValue = 1.f;
		if(Multipliers.Num() > 0)
		{
			FinalValue = 0;
			for(AMoleStealthSoundMultiplier Mul : Multipliers)
			{
				if(Mul == nullptr)
					continue;

				const float Distance = PlayerLocation.DistSquared(Mul.GetActorLocation());
				const float Alpha = 1.f - FMath::Min(1.f, Distance / FMath::Square(Mul.PlayerTrigger.GetSphereRadius()));
				const float CurveValue = Mul.MultiplierCurve.GetFloatValue(Alpha);
				if(CurveValue > FinalValue)
					FinalValue = CurveValue;
			}
		}

		return FinalValue;
	}

	bool PlayersAreDetected() const
	{
		if(CurrentVolume + CurrentSecondLifeVolume >= MoleStealthSettings::MaxVolume + MoleStealthSettings::MaxVolumeSecondLife)
			return true;
		return false;
	}

	void ResetVolume()
	{
		CurrentVolume = 0;
		CurrentSecondLifeVolume = 0;
		bHasIncreasedFinalTimeThisFrame = false;
		TimeLeftToDecreaseSound = 0;
	}

	void GetVolume(float& OutVolume, float& OutSecondLifeVolume) const
	{
		OutVolume = float(CurrentVolume);
		OutSecondLifeVolume = float(CurrentSecondLifeVolume);
	}
}