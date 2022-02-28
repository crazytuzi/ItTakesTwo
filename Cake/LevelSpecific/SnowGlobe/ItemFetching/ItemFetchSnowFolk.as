import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchDropOffPoint;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowfolkFetchQuestNPC;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;

enum EFetchSnowFolkState
{
	Sad, //if player is not near or item is not near
	HoldingSignToPlayer, //if player is close but item is not present
	PointingToBasket, //if player is holding item and near
	PointingToFish, //if fish is near on the ground
	Celebrating, //if player puts fish in basket
	Happy //if have fish
};

class AItemFetchSnowFolk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)	
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	// default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)	
	UHazeCharacterSkeletalMeshComponent SkeletalMesh;

	UPROPERTY(Category = "Setup")
	AItemFetchDropOffPoint DropOffPoint;

	UPROPERTY(Category = "Setup")
	AHazeActor WantedItem;

	UPROPERTY(Category = "Setup")
	AHazeActor SignBoard;

	UPROPERTY(Category = "Capabilities")
	TSubclassOf<UHazeCapability> Capability;

	TPerPlayer<UItemFetchPlayerComp> PlayerComps;

	UPROPERTY(BlueprintReadOnly)
	USnowfolkFetchQuestNPCFeature LocomotionFeature;

	UPROPERTY()
	EFetchSnowFolkState FetchSnowFolkState;

	TPerPlayer<float> DistanceFromPlayer;

	TPerPlayer<bool> PlayerInRange;

	bool bHaveRecievedItem;

	bool bSeesPlayerHasitem;

	float MinPlayerRadius = 2000.f; 

	float PlayerDistanceRadius = 2500.f;

	//TODO Snowball Hit Reaction
	UPROPERTY(DefaultComponent)	
	USnowballFightResponseComponent SnowballFightResponseComponent;
	
	float Timer;

	UPROPERTY()
	bool bCanTriggerSnowballhit;

	UPROPERTY()
	FVector LookAtLocation;

	// UPROPERTY()
	// FRotator BodyRotation;

	// UPROPERTY()
	// FRotator HeadRotation;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(Capability);

		PlayerComps[0] = UItemFetchPlayerComp::Get(Game::GetMay());
		PlayerComps[1] = UItemFetchPlayerComp::Get(Game::GetCody());

		DropOffPoint.EventItemReceived.AddUFunction(this, n"EventFinished");

		SnowballFightResponseComponent.OnSnowballHit.AddUFunction(this, n"HitBySnowBall");	

		if (bHaveRecievedItem)
		{
			//snap item to snowfolk location where they can pick it up?
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayerComps[0] == nullptr)
			PlayerComps[0] = UItemFetchPlayerComp::Get(Game::GetMay());

		if (PlayerComps[1] == nullptr)
			PlayerComps[1] = UItemFetchPlayerComp::Get(Game::GetCody());

		if (bCanTriggerSnowballhit)
		{
			Timer -= DeltaTime;

			if (Timer <= 0.f)
				bCanTriggerSnowballhit = false;
		}

		// PrintToScreen("FetchSnowFolkState: " + FetchSnowFolkState);
	}

	UFUNCTION()
	void HitBySnowBall(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		if (!bCanTriggerSnowballhit)
		{
			bCanTriggerSnowballhit = true;
			SkeletalMesh.SetAnimBoolParam(n"bHitBySnowball", true);
			Timer = 2.f;
		}
	}

	UFUNCTION()
	void CheckingIfPlayerHasItem()
	{
		if (PlayerComps[0] == nullptr || PlayerComps[1] == nullptr)
			return;

		if (PlayerComps[0].bHoldingItem && PlayerInRange[0])
		{
			bSeesPlayerHasitem = true;
		}
		else if (PlayerComps[1].bHoldingItem && PlayerInRange[1])
		{
			bSeesPlayerHasitem = true;
		}
		else
		{
			bSeesPlayerHasitem = false;
		}
	}

	void CheckItemDistance()
	{
		if (DropOffPoint.bHaveReceived)
			return;

		if (PlayerComps[0] == nullptr || PlayerComps[1] == nullptr)
			return;

		float Distance = (DropOffPoint.Item.ActorLocation - DropOffPoint.ActorLocation).Size();

		if (Distance < DropOffPoint.MinCanDropDistance)
		{
			PlayerComps[0].DropOffPoint = this;
			PlayerComps[1].DropOffPoint = this;

			PlayerComps[0].bCanDropOff = true;
			PlayerComps[1].bCanDropOff = true;
		}
		else
		{
			if (PlayerComps[0].DropOffPoint == this)
			{
				PlayerComps[0].bCanDropOff = false;
				PlayerComps[0].DropOffPoint = nullptr;
			}

			if (PlayerComps[1].DropOffPoint == this)
			{
				PlayerComps[1].DropOffPoint = nullptr;
				PlayerComps[1].bCanDropOff = false;	
			}
		}

		if (Distance < DropOffPoint.MinItemDistance && !DropOffPoint.bHaveReceived && DropOffPoint.Item.bIsGrounded)
		{
			DropOffPoint.EventItemReceived.Broadcast();
			DropOffPoint.bHaveReceived = true;
		}
	}

	void CheckPlayerDistance()
	{
		DistanceFromPlayer[0] = (Game::GetMay().ActorLocation - ActorLocation).Size();
		DistanceFromPlayer[1] = (Game::GetCody().ActorLocation - ActorLocation).Size();

		if (DistanceFromPlayer[0] <= PlayerDistanceRadius)
			PlayerInRange[0] = true;
		else 
			PlayerInRange[0] = false;

		if (DistanceFromPlayer[1] <= PlayerDistanceRadius)
			PlayerInRange[1] = true;
		else 
			PlayerInRange[1] = false;
	}

	UFUNCTION()
	void EventFinished()
	{
		bHaveRecievedItem = true;
	}
}