import Cake.LevelSpecific.SnowGlobe.Curling.CurlingTube;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;
import Cake.LevelSpecific.SnowGlobe.Curling.StaticsCurling;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;

class ACurlingStartingLine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root; 

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	ACurlingStone CurrentStone;

	TPerPlayer<AHazePlayerCharacter> Players;

	TPerPlayer<UCurlingPlayerComp> PlayerComps;

	float StoneRadiusCheck = -132.5f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Players[0] = Game::GetMay(); 
		Players[1] = Game::GetCody();
	}

	UFUNCTION()
	void SetPlayerCompReferences()
	{
		PlayerComps[0] = UCurlingPlayerComp::Get(Players[0]);
		PlayerComps[1] = UCurlingPlayerComp::Get(Players[1]);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayerComps[0] == nullptr)
			return;

		if (PlayerComps[1] == nullptr)
			return;

		ACurlingStone Stone1 = Cast<ACurlingStone>(PlayerComps[0].TargetStone);
		ACurlingStone Stone2 = Cast<ACurlingStone>(PlayerComps[1].TargetStone);

		FVector StoneDelta1;
		FVector StoneDelta2;

		if (Stone1 != nullptr)
			StoneDelta1 = Stone1.ActorLocation - ActorLocation;

		if (Stone2 != nullptr)
			StoneDelta2 = Stone2.ActorLocation - ActorLocation;  
		
		float StoneDistance1 = ActorForwardVector.DotProduct(StoneDelta1);
		float StoneDistance2 = ActorForwardVector.DotProduct(StoneDelta2);
			
		if (PlayerComps[0].PlayerCurlState == EPlayerCurlState::MoveStone || PlayerComps[0].PlayerCurlState == EPlayerCurlState::Targeting)
		{
			if (StoneDistance1 > StoneRadiusCheck)
			{
				if (PlayerComps[0].bCanTargetAndFire)
				{
					PlayerComps[0].bCanTargetAndFire = false;
					PlayerComps[0].HideCurlShootPrompt(Game::GetMay());
				}
			}
			else
			{
				if (!PlayerComps[0].bCanTargetAndFire)
				{
					PlayerComps[0].bCanTargetAndFire = true;
					PlayerComps[0].ShowCurlShootPrompt(Game::GetMay());
				}
			}
		}
		else
		{
			if (PlayerComps[0].bCanTargetAndFire)
			{
				PlayerComps[0].bCanTargetAndFire = false;
				PlayerComps[0].HideCurlShootPrompt(Game::GetMay());
			}
		}

		if (PlayerComps[1].PlayerCurlState == EPlayerCurlState::MoveStone || PlayerComps[1].PlayerCurlState == EPlayerCurlState::Targeting)
		{
			
			if (StoneDistance2 > StoneRadiusCheck)
			{
				if (PlayerComps[1].bCanTargetAndFire)
				{
					PlayerComps[1].bCanTargetAndFire = false;
					PlayerComps[1].HideCurlShootPrompt(Game::GetCody());
				}
			}
			else
			{
				if (!PlayerComps[1].bCanTargetAndFire)
				{
					PlayerComps[1].bCanTargetAndFire = true;
					PlayerComps[1].ShowCurlShootPrompt(Game::GetCody());
				}
			}
		}
		else
		{
			if (PlayerComps[1].bCanTargetAndFire)
			{
				PlayerComps[1].bCanTargetAndFire = false;
				PlayerComps[1].HideCurlShootPrompt(Game::GetMay());
			}
		}
	}
}