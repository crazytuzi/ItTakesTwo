import Cake.Environment.BreakableComponent;

event void FOnExplodingIceBreak();

class AExplodingIce : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UBreakableComponent BreakableComponent;	

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Arrow;

	UPROPERTY()
	FOnExplodingIceBreak OnExplodingIceBreak;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		BreakableComponent.ConstructionScript_Hack();
    }

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void Break()
	{
	//	OnExplodingIceBreak.Broadcast();
	}
}