import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAudio.CastleEnemyAudioBaseCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;

class UCastleChessPieceAudioCapability : UCastleEnemyAudioBaseCapability
{	

	UChessPieceComponent ChessPieceComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);

		EnemyHazeAkComp.SetTrackVelocity(false);
		bBlockMovementAudio = true;
		ChessPieceComp = UChessPieceComponent::Get(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime) override
	{
		Super::TickActive(DeltaTime);

		if(ConsumeAction(n"AudioPiecePerformAttack") == EActionStateStatus::Active)
			ChessPieceComp.OnChessPieceAttack.Broadcast();

		if(ConsumeAction(n"AudioPieceDespawn") == EActionStateStatus::Active)
			ChessPieceComp.OnChessPieceDespawn.Broadcast();
	}	
}