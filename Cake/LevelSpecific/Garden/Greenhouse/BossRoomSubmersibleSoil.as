import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoilComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantPlayerComponent;
import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Peanuts.Aiming.AutoAimTarget;

event void FOnPlayerSubmergedInBossSoil(AHazePlayerCharacter Player);
event void FOnPlayerLeftBossSoil();
event void FOnStartedControllingNewSection();

class ABossRoomSubmersibleSoil : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SoilMesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent ActiveSoilEffect;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GroundPoundWidgetLocation;
	//UPROPERTY(DefaultComponent, Attach = SoilMesh)
	//USphereComponent WaterCollider;
	UPROPERTY(DefaultComponent, Attach = SoilMesh)
	UWaterHoseImpactComponent WaterHoseImpactComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent EnterJoySoilAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExitJoySoilAudioEvent;

	UPROPERTY()
	UAnimSequence CodyEnterAnimation;

	UPROPERTY()
	APlayerTrigger WidgetTrigger;

	UPROPERTY()
	AActor ExitLocation;
	UPROPERTY()
	AActor ActorToJumpTo;
	UPROPERTY()
	TSubclassOf<UHazeUserWidget> GroundPoundWidget;
	UPROPERTY(Transient)
	UHazeUserWidget GPWidget;
	UPROPERTY()
	UNiagaraSystem ExitSoilVFX;
	UPROPERTY()
	FOnPlayerSubmergedInBossSoil OnPlayerSubmergedInBossSoil;
	UPROPERTY()
	FOnPlayerLeftBossSoil OnPlayerLeftBossSoil;
	AHazePlayerCharacter PlayerInSoil;
	UPROPERTY()
	bool bIsUsable = false;
	UPROPERTY()
	UMaterialInstance DirtMaterial;
	UMaterialInstanceDynamic MeshMaterialInstanceDynamic;
	UPROPERTY()
	int NumberOfControlSections = 1;
	UPROPERTY()
	UNiagaraSystem EnterSoilVFX;
	int CurrentSection = 1;
	bool bWidgetIsVisible = false;

	FHazeAcceleratedFloat Acceleratedfloat;
	bool bMakeWet = false;
	bool bMakeDry = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActiveSoilEffect.Deactivate();
		WidgetTrigger.OnPlayerEnter.AddUFunction(this, n"OnEnterWidgetTrigger");
		WidgetTrigger.OnPlayerLeave.AddUFunction(this, n"OnLeftWidgetTrigger");	
		WaterHoseImpactComp.OnFullyWatered.AddUFunction(this, n"OnFullyWatered");
		WaterHoseImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		MeshMaterialInstanceDynamic = SoilMesh.CreateDynamicMaterialInstance(0);

		FActorGroundPoundedDelegate GroundPoundedDelegate;
        GroundPoundedDelegate.BindUFunction(this, n"GroundPounded");
        BindOnActorGroundPounded(this, GroundPoundedDelegate);

		UGroundPoundedCallbackComponent GroundPoundComp = UGroundPoundedCallbackComponent::GetOrCreate(this);
		GroundPoundComp.Evaluate.BindUFunction(this, n"EvalOnGroundPounded");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bMakeWet == true)
		{
			Acceleratedfloat.SpringTo(1, 40, 1, DeltaTime);
			MeshMaterialInstanceDynamic.SetVectorParameterValue(n"Tiler_B_Mask_VertexColor", FLinearColor(Acceleratedfloat.Value, 0.f, 0.f, 0.f));
		}
		if(bMakeDry == true)
		{
			Acceleratedfloat.SpringTo(0, 40, 1, DeltaTime);
			MeshMaterialInstanceDynamic.SetVectorParameterValue(n"Tiler_B_Mask_VertexColor", FLinearColor(Acceleratedfloat.Value, 0.f, 0.f, 0.f));
		}
	}

	UFUNCTION()
	void OnFullyWatered()
	{
		WaterHoseImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		bIsUsable = true;	
		ActiveSoilEffect.Activate();	

		bMakeWet = true;
		System::SetTimer(this, n"DisableMaterialLerp", 3.f, false);
		
		TArray<AActor> Actors;
		WidgetTrigger.GetOverlappingActors(Actors);

		for (auto Actor : Actors)
		{
			auto Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player == Game::GetCody())
			{
				ShowWidget();
			}
		}
	}

	UFUNCTION()
	void DisableMaterialLerp()
	{
		bMakeDry = false;
		bMakeWet = false;
	}


	UFUNCTION(NotBlueprintCallable)
	protected bool EvalOnGroundPounded(AHazePlayerCharacter EnteringPlayer, UPrimitiveComponent Floor)const
	{
		if(EnteringPlayer.IsMay())
		 	return false;
		
		if(!bIsUsable)
			return false;
			
		return true;
	}
	UFUNCTION()
	void GroundPounded(AHazePlayerCharacter Player)
	{
		SubmergeInBossSoil(Player);
	}

	//Networked through groundpound
	UFUNCTION()
	void SubmergeInBossSoil(AHazePlayerCharacter Player)
	{
		PlayerInSoil = Player;
		HideWidget();
		Game::GetMay().DisableOutlineByInstigator(this);
		Niagara::SpawnSystemAtLocation(EnterSoilVFX, Game::GetCody().GetActorLocation(), Game::GetCody().GetActorRotation(), bAutoDestroy=true);
		Player.PlayerHazeAkComp.HazePostEvent(EnterJoySoilAudioEvent);
		PlayerInSoil.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerInSoil.BlockCapabilities(CapabilityTags::Collision, this);
		PlayerInSoil.MeshOffsetComponent.OffsetRelativeLocationWithTime(FVector(0.f, 0.f, /*-180.f*/ - 250.0f), 0.25f);
		PlayerInSoil.Mesh.RemoveOutlineFromMesh(this);
		Player.BlockMovementSyncronization();
		Player.TriggerMovementTransition(this);


		//Game::GetCody().SetCapabilityActionState(n"ControllingJoy", EHazeActionState::Active);
		Game::GetCody().Tags.Add(n"ControllingJoy");
		Player.AddPlayerInvulnerability(this);
		
		FHazePlaySlotAnimationParams Params;
		Params.Animation = CodyEnterAnimation;
		Params.bPauseAtEnd = true;
		Params.BlendTime = 0.f;
		Player.PlaySlotAnimation(Params);

		MakeBossSoilNotUsable();
		OnPlayerSubmergedInBossSoil.Broadcast(PlayerInSoil);
		
	}

	//networked through mays ability when blob explodes
	UFUNCTION()
	void LeaveBossSoil()
	{
		WaterHoseImpactComp.ResetWaterLevel();
		PlayerInSoil.TeleportActor(ExitLocation.GetActorLocation(), ExitLocation.GetActorRotation());
		PlayerInSoil.UnblockMovementSyncronization();
		Niagara::SpawnSystemAtLocation(ExitSoilVFX, ExitLocation.GetActorLocation(), ExitLocation.GetActorRotation(), bAutoDestroy=true);
		PlayerInSoil.PlayerHazeAkComp.HazePostEvent(ExitJoySoilAudioEvent);
		PlayerInSoil.MeshOffsetComponent.ResetLocationWithTime(0.25f);
		Game::GetMay().EnableOutlineByInstigator(this);
		//PlayerInSoil.Mesh.CreateMeshOutlineBasedOnPlayer(this);
		PlayerInSoil.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerInSoil.UnblockCapabilities(CapabilityTags::Collision, this);

		//Game::GetCody().SetCapabilityActionState(n"ControllingJoy", EHazeActionState::Inactive);
		Game::GetCody().Tags.Remove(n"ControllingJoy");
		RemovePlayerInvulnerability(PlayerInSoil, this);

		bMakeDry = true;
		System::SetTimer(this, n"DisableMaterialLerp", 3.f, false);

		PlayerInSoil.StopAllSlotAnimations();

		FHazeJumpToData JumpData;
		JumpData.AdditionalHeight = 800;
		JumpData.Transform = ActorToJumpTo.GetActorTransform();
		JumpTo::ActivateJumpTo(PlayerInSoil, JumpData);

		OnPlayerLeftBossSoil.Broadcast();
	}


	UFUNCTION()
	void MakeBossSoilUsable()
	{
		WaterHoseImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
	}
	UFUNCTION()
	void MakeBossSoilNotUsable()
	{
		bIsUsable = false;		
		ActiveSoilEffect.Deactivate();
	}

	void ShowWidget()
	{
		if(bWidgetIsVisible)
			return;

		if(GPWidget == nullptr)
			GPWidget = Game::GetCody().AddWidget(GroundPoundWidget);
		else
			Game::GetCody().AddExistingWidget(GPWidget);	

		GPWidget.AttachWidgetToComponent(GroundPoundWidgetLocation);
		bWidgetIsVisible = true;
	}

	void HideWidget()
	{
		if(GPWidget == nullptr)
			return;

		bWidgetIsVisible = false;
		Game::GetCody().RemoveWidget(GPWidget);
	}

	UFUNCTION()
	void OnEnterWidgetTrigger(AHazePlayerCharacter Player)
	{
		if(bIsUsable == false)
			return;
		if(Player != Game::GetCody())
			return;
		
		ShowWidget();
	}
	UFUNCTION()
	void OnLeftWidgetTrigger(AHazePlayerCharacter Player)
	{
		if(bIsUsable == false)
			return;
		if(Player != Game::GetCody())
			return;

		HideWidget();
	}
}
