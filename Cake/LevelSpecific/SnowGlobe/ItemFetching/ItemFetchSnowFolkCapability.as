import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchSnowFolk;
import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchPickUp;

class UItemFetchSnowFolkCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ItemFetchSnowFolkCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AItemFetchSnowFolk SnowFolk;

	AItemFetchPickUp PickUp;

	TPerPlayer<AHazePlayerCharacter> Players;
	TPerPlayer<float> Distances; 

	AHazePlayerCharacter ClosestPlayer;

	TPerPlayer<UItemFetchPlayerComp> PlayerComps;

	FRotator InitialRotation;
	FVector InitialForward;

	FHazeAcceleratedRotator AcceleratedRotator;

	FRotator TargetRot;

	float HeadDot;

	float Radius = 2500.f;
	float Timer;

	bool bHaveFlungSignAway;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SnowFolk = Cast<AItemFetchSnowFolk>(Owner);
		InitialForward = SnowFolk.ActorForwardVector;
		InitialRotation = SnowFolk.ActorForwardVector.Rotation();
		PickUp = Cast<AItemFetchPickUp>(SnowFolk.WantedItem);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Players[0] = Game::GetMay();
		Players[1] = Game::GetCody();

		SnowFolk.DropOffPoint.EventItemReceived.AddUFunction(this, n"ActivateCelebrating");

		AcceleratedRotator.SnapTo(SnowFolk.ActorRotation);

		if (!SnowFolk.bHaveRecievedItem)
			AttachSign();
		else
			AttachItem();
		
		Timer = 1.8f;

		PlayerComps[0] = UItemFetchPlayerComp::Get(Players[0]);
		PlayerComps[1] = UItemFetchPlayerComp::Get(Players[1]);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Players[0] == nullptr || Players[1] == nullptr)
			return;

		Distances[0] = (Players[0].ActorLocation - SnowFolk.ActorLocation).Size();
		Distances[1] = (Players[1].ActorLocation - SnowFolk.ActorLocation).Size();

		ClosestPlayer = (Distances[0] < Distances[1]) ? Game::May : Game::Cody;

		SnowFolk.CheckingIfPlayerHasItem();
		SnowFolk.CheckPlayerDistance();
		SnowFolk.CheckItemDistance();
		StateHandler(DeltaTime);
		LookAtHandler(DeltaTime);
	}

	UFUNCTION()
	void StateHandler(float DeltaTime)
	{
		if (SnowFolk.FetchSnowFolkState == EFetchSnowFolkState::Celebrating)
		{
			Timer -= DeltaTime;

			if (Timer <= 0.f && !bHaveFlungSignAway)
			{
				bHaveFlungSignAway = true;
				DetachSign();
			}
			return;
		}
		
		float ItemDistance = (SnowFolk.WantedItem.ActorLocation - SnowFolk.ActorLocation).Size();

		if (Distances[0] <= SnowFolk.MinPlayerRadius || Distances[1] <= SnowFolk.MinPlayerRadius)
		{
			if (!SnowFolk.bHaveRecievedItem)
			{
				if (SnowFolk.bSeesPlayerHasitem)
					SnowFolk.FetchSnowFolkState = EFetchSnowFolkState::PointingToBasket;
				else if (ItemDistance <= SnowFolk.MinPlayerRadius)
					SnowFolk.FetchSnowFolkState = EFetchSnowFolkState::PointingToFish;
				else
					SnowFolk.FetchSnowFolkState = EFetchSnowFolkState::HoldingSignToPlayer;
			}
			else
			{
				SnowFolk.FetchSnowFolkState = EFetchSnowFolkState::Happy;
			}
		}
		else
		{
			if (!SnowFolk.bHaveRecievedItem)
				SnowFolk.FetchSnowFolkState = EFetchSnowFolkState::Sad;
			else 
				SnowFolk.FetchSnowFolkState = EFetchSnowFolkState::Happy;
		}
	}

	UFUNCTION()
	void LookAtHandler(float DeltaTime)
	{
		if (SnowFolk.FetchSnowFolkState == EFetchSnowFolkState::HoldingSignToPlayer)
			SnowFolk.LookAtLocation = ClosestPlayer.ActorLocation;
		else if (SnowFolk.FetchSnowFolkState == EFetchSnowFolkState::PointingToFish)
		{
			SnowFolk.LookAtLocation = SnowFolk.WantedItem.ActorLocation;
		}
		else if (SnowFolk.FetchSnowFolkState == EFetchSnowFolkState::PointingToBasket)
		{
				if (PlayerComps[0].bHoldingItem)
					SnowFolk.LookAtLocation = Players[0].ActorLocation;
				else 
					SnowFolk.LookAtLocation = Players[1].ActorLocation;
		}
		else
			SnowFolk.LookAtLocation = InitialRotation.ForwardVector * 100.f;
		
		FRotator NewRot = FMath::RInterpConstantTo(SnowFolk.ActorRotation, TargetRot, DeltaTime, 3920.f);
		AcceleratedRotator.AccelerateTo(NewRot, 1.35f, DeltaTime);
	}

	UFUNCTION()
	void ActivateCelebrating()
	{
		SnowFolk.FetchSnowFolkState = EFetchSnowFolkState::Celebrating;
		System::SetTimer(this, n"DeactivateCelebrating", 3.f, false);
	}

	UFUNCTION()
	void DeactivateCelebrating()
	{
		SnowFolk.FetchSnowFolkState = EFetchSnowFolkState::Happy;
	}

	UFUNCTION()
	void AttachSign()
	{
		if (SnowFolk.SignBoard == nullptr)
			return;

		SnowFolk.SignBoard.AttachToComponent(SnowFolk.SkeletalMesh, n"RightAttach", EAttachmentRule::SnapToTarget);
	}

	UFUNCTION()
	void DetachSign()
	{
		if (SnowFolk.SignBoard == nullptr)
			return;

		SnowFolk.SignBoard.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

	UFUNCTION()
	void AttachItem()
	{

	}

	UFUNCTION()
	void DettachItem()
	{
		//probably not needed
	}
}