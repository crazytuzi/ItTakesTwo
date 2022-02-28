
class APlayerJetpackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USkeletalMeshComponent JetpackMesh;
	default JetpackMesh.ShadowPriority = EShadowPriority::Player;

	// Called when swithing to flying mode
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Enter Flying"))
	void BP_OnEnterFlying(){}

	// Called when swithing to hover mode
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Enter Hover"))
	void BP_OnEnterHover(){}

	// Called when the player is no longer flying or hovering. Should be used to turn of effects etc.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Exit Flying"))
	void BP_OnExitFlying(){}
}
