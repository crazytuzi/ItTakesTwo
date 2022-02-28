
struct FCymbalHitInfo
{
	// The Cymbal that sent this event.
	UPROPERTY(BlueprintReadOnly, Category = Cymbal, meta = (DisplayName = "Cymbal"))
	AHazeActor Owner;
	// The actor that instigated this hit, the holder of the cymbal, such as the player.
	UPROPERTY(BlueprintReadOnly, Category = Cymbal)
	AHazeActor Instigator;
	// The component that was hit.
	UPROPERTY(BlueprintReadOnly, Category = Cymbal)
	UPrimitiveComponent HitComponent;
	UPROPERTY(BlueprintReadOnly, Category = Cymbal)
	FVector HitLocation;
	// The last movement made by the Cymbal before impact
	UPROPERTY(BlueprintReadOnly, Category = Cymbal, meta = (DisplayName = "Direction"))
	FVector DeltaMovement;
	// This hit was executed because an auto aim target was successfully hit.
	UPROPERTY(BlueprintReadOnly, Category = Cymbal)
	bool bAutoAimHit = false;
}
