import Vino.Interactions.InteractionComponent;
import Vino.Interactions.DoubleInteractionActor;

event void FHoopsInteractionSignature();

class AHoopsStartInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot1;

	UPROPERTY(DefaultComponent, Attach = MeshRoot1)
	UStaticMeshComponent ButtonMay;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot2;

	UPROPERTY(DefaultComponent, Attach = MeshRoot2)
	UStaticMeshComponent ButtonCody;

	UPROPERTY()
	FHoopsInteractionSignature HoopsInteractedReady;

	UPROPERTY()
	ADoubleInteractionActor DoubleInteractActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoubleInteractActor.OnDoubleInteractionCompleted.AddUFunction(this, n"InteractionCompleted");
		DoubleInteractActor.OnBothPlayersLockedIntoInteraction.AddUFunction(this, n"PlayersLockedIn");
	}

	UFUNCTION()
	void PlayersLockedIn()
	{
		HoopsInteractedReady.Broadcast();
	}

	UFUNCTION()
	void InteractionCompleted()
	{
		AllowInteractionToComplete(false);
	}

	void AllowInteractionToComplete(bool bAllow)
	{
		DoubleInteractActor.bPreventInteractionFromCompleting = !bAllow;
	}

	UFUNCTION()
	void EnableInteraction(bool bEnable)
	{
		if (bEnable)
		{
			DoubleInteractActor.EnableAfterFullSyncPoint(n"HoopsStart");
			ResetHoopsButtons();
		}
		else
			DoubleInteractActor.Disable(n"HoopsStart");
		
	}
	
	UFUNCTION(BlueprintEvent)
	void ResetHoopsButtons(){}
}