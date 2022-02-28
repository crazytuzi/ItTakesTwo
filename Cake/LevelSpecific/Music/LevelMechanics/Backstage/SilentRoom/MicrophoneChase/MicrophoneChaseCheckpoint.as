import Vino.Checkpoints.Checkpoint;
class AMicrophoneChaseCheckpoint : ACheckpoint
{
	bool bCheckpointShouldFollowPlayers = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//System::DrawDebugSphere(GetActorLocation());
	}

	UFUNCTION()
	void SetFollowPlayersEnabled(bool bEnabled)
	{
		bCheckpointShouldFollowPlayers = bEnabled;
	}

	UFUNCTION()
	void UpdateChaseCheckpointLocationAndRotation(FVector NewLocation, FRotator NewRotation)
	{
		SetActorLocationAndRotation(NewLocation, NewRotation);
	}
}