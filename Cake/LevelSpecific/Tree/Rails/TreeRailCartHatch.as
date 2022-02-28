import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.PlayerHealth.PlayerHealthStatics;

class UTreeRailCartHatchRoot : USceneComponent
{
	ATreeRailCartHatch HatchOwner;
	bool bIsActorEnabled = true;
	FRotator TargetRotation;
	FRotator CurrentRotation;
	AHazePlayerCharacter LastPlayerThatCouldSee;

	// This component never disables
	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		bIsActorEnabled = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		bIsActorEnabled = true;
		HatchOwner.HatchRotation.RelativeRotation = CurrentRotation;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()	
	{
		HatchOwner = Cast<ATreeRailCartHatch>(Owner);
		HatchOwner.DisableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Cody = Game::GetCody();
		auto May = Game::GetMay();
		const float DistanceToCody = HatchOwner.KillPlayerTrigger.GetWorldLocation().DistSquared(Cody.GetActorLocation());
		const float DistanceToMay = HatchOwner.KillPlayerTrigger.GetWorldLocation().DistSquared(May.GetActorLocation());

		float ClosestDistance;
		AHazePlayerCharacter ClosestPlayer;
		if(DistanceToCody < DistanceToMay)
		{
			ClosestPlayer = Cody;
			ClosestDistance = DistanceToCody;
		}
		else
		{
			ClosestPlayer = May;
			ClosestDistance = DistanceToMay;
		}

		if(ClosestDistance < FMath::Square(2000.f))
		{
			if(Trace::ComponentOverlapComponent(
				ClosestPlayer.CapsuleComponent,
				HatchOwner.KillPlayerTrigger,
				HatchOwner.KillPlayerTrigger.WorldLocation,
				HatchOwner.KillPlayerTrigger.ComponentQuat,
				false))
			{
				KillPlayer(ClosestPlayer, HatchOwner.DeathEffect);
			}
		}

		if(LastPlayerThatCouldSee == nullptr)
			LastPlayerThatCouldSee = ClosestPlayer;

		bool bAnyPlayerCanSee = HatchOwner.Hatch.WasRecentlyRendered(1.f);
		if(!bAnyPlayerCanSee)
		{	
			const float VisibilityDistance = 12000.f;
			const float ViewSize = 900.f;
			if(SceneView::ViewFrustumPointRadiusIntersection(LastPlayerThatCouldSee, HatchOwner.GetActorLocation(), ViewSize, VisibilityDistance))
			{
				bAnyPlayerCanSee = true;
			}
			else if(SceneView::ViewFrustumPointRadiusIntersection(LastPlayerThatCouldSee.GetOtherPlayer(), HatchOwner.GetActorLocation(), ViewSize, VisibilityDistance))
			{
				bAnyPlayerCanSee = true;
				LastPlayerThatCouldSee = LastPlayerThatCouldSee.GetOtherPlayer();
			}
		}

		if(bAnyPlayerCanSee != bIsActorEnabled)
		{
			if(bAnyPlayerCanSee)
				HatchOwner.EnableActor(this);
			else
				HatchOwner.DisableActor(this);
		}

		CurrentRotation = FMath::RInterpTo(CurrentRotation, TargetRotation, DeltaSeconds, 5.f);
		if(bIsActorEnabled)
		{
			HatchOwner.HatchRotation.RelativeRotation = CurrentRotation;
		}
	}
}

UCLASS(Abstract)
class ATreeRailCartHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UTreeRailCartHatchRoot ActiveRoot;

	UPROPERTY(DefaultComponent, Attach = ActiveRoot)
	USceneComponent HatchRotation;

	UPROPERTY(DefaultComponent, Attach = HatchRotation)
	UStaticMeshComponent Hatch;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;

	UPROPERTY(DefaultComponent, Attach = ActiveRoot)
	UBoxComponent KillPlayerTrigger;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	AActor SplineOwner;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	TArray<AHazeActor> OverlappingCarts;

	void AddOverlappingCart(AHazeActor Cart)
	{
		OverlappingCarts.Add(Cart);
		if(OverlappingCarts.Num() == 1)
		{
			ActiveRoot.TargetRotation = FRotator(90.f, 0.f, 0.f);
			BeginCartOverlap();
		}
	}

	void RemoveOverlappingCart(AHazeActor Cart)
	{
		OverlappingCarts.RemoveSwap(Cart);
		if(OverlappingCarts.Num() == 0)
		{
			ActiveRoot.TargetRotation = FRotator(0.f, 0.f, 0.f);
			EndCartOverlap();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BeginCartOverlap() 
	{
	}

	UFUNCTION(BlueprintEvent)
	void EndCartOverlap() 
	{
	}
}