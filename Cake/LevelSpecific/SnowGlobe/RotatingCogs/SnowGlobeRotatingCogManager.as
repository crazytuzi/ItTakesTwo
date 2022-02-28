
class ASnowGlobeRotatingCogManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UBoxComponent FrustumValidation;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bActorIsVisualOnly = true;
	default Disable.bAutoDisable = true;
	default Disable.AutoDisableRange = 25000.f;

	UPROPERTY(EditConst)
	TArray<AStaticMeshActor> ControlledActors;

	UPROPERTY(EditConst)
	TArray<URotatingMovementComponent> ControlledActorMovementComps;

	TPerPlayer<bool> bHasNetworkBegunPlay;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		ControlledActors.Reset();
		ControlledActorMovementComps.Reset();

		TArray<AActor> Attachments;
		GetAttachedActors(Attachments);

		for(auto Actor : Attachments)
		{
			auto MeshActor = Cast<AStaticMeshActor>(Actor);
			if(MeshActor != nullptr)
				ControlledActors.Add(MeshActor);

			auto Movement = URotatingMovementComponent::Get(MeshActor);

			// We block the movement until both sides are ready to tick
			Movement.bRotationIsBlocked = true;
			Movement.bUpdateOnlyIfRendered = true;
			ControlledActorMovementComps.Add(Movement);
		}

		DisableActor(this);

		for(auto Player : Game::GetPlayers())
		{
			if(!Player.HasControl())
				continue;

			NetSendHasBegunPlay(Player);
		}		
	}

	UFUNCTION(NetFunction)
	private void NetSendHasBegunPlay(AHazePlayerCharacter Player)
	{
		bHasNetworkBegunPlay[Player.Player] = true;
		if(HasControl() && bHasNetworkBegunPlay[Player.GetOtherPlayer().Player])
		{
			NetEnableCogs(Network::GetPingRoundtripSeconds());
		}
	}

	UFUNCTION(NetFunction)
	private void NetEnableCogs(float Delay)
	{
		// we use the ping to delay the start so both sides are as close as possible to eachother
		if(HasControl() && Network::IsNetworked())
			System::SetTimer(this, n"EnableCogs", FMath::Max(Delay, KINDA_SMALL_NUMBER), false);
		else
			System::SetTimer(this, n"EnableCogs", FMath::Max(Delay * 0.5f, KINDA_SMALL_NUMBER), false);
	}

	UFUNCTION(NotBlueprintCallable)
	private void EnableCogs()
	{
		for(auto Movement : ControlledActorMovementComps)
		{
			Movement.SetUpdatePersistant(true);
			Movement.bRotationIsBlocked = false;
		}
		EnableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(int i = 0; i < ControlledActors.Num(); ++i)
		{
			ControlledActors[i].SetActorTickEnabled(true);
			ControlledActors[i].SetActorHiddenInGame(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorPostDisabled()
	{
		for(int i = 0; i < ControlledActors.Num(); ++i)
		{
			ControlledActors[i].SetActorTickEnabled(false);
			ControlledActors[i].SetActorHiddenInGame(true);
		}
	}
}