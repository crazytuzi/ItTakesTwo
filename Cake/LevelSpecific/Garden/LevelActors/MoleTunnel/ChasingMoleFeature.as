class UChasingMoleFeature : UHazeLocomotionFeatureBase
{
    UChasingMoleFeature()
    {
        Tag = n"MoleChase";
    }

    UPROPERTY(Category = "MoleChase")
    FHazePlayBlendSpaceData MoveBS;
	UPROPERTY(Category = "MoleChase")
    FHazePlaySequenceData AttackLeft;
	UPROPERTY(Category = "MoleChase")
    FHazePlaySequenceData AttackRight;
	UPROPERTY(Category = "MoleChase")
    FHazePlaySequenceData AttackForward;
	UPROPERTY(Category = "MoleChase")
    FHazePlaySequenceData Enter;
	UPROPERTY(Category = "MoleChase")
    FHazePlayRndSequenceData Jump;
	UPROPERTY(Category = "MoleChase")
    FHazePlaySequenceData Impact;

	//The top down section where there are two moles chasing the players
	UPROPERTY(Category = "MoleDouble")
    FHazePlayBlendSpaceData MoveLeft;

	UPROPERTY(Category = "MoleDouble")
    FHazePlayBlendSpaceData MoveRight;

	UPROPERTY(Category = "MoleDouble")
    FHazePlaySequenceData ImpactLeft;

	UPROPERTY(Category = "MoleDouble")
    FHazePlaySequenceData ImpactRight;

	//The section where the players are jumping on the mole stuck in the shaft

	UPROPERTY(Category = "MoleStuck")
	FHazePlaySequenceData MoleStuckFalling;

	UPROPERTY(Category = "MoleStuck")
	FHazePlayRndSequenceData MoleStuckGesture;

	UPROPERTY(Category = "MoleStuck")
	FHazePlaySequenceData SmallBump;

	UPROPERTY(Category = "MoleStuck")
	FHazePlaySequenceData BigBump;

	UPROPERTY(Category = "MoleStuck")
	FHazePlaySequenceData EndPosition;

	UPROPERTY(Category = "MoleStuck")
	FHazePlaySequenceData SmallBumpEnd;

	UPROPERTY(Category = "MoleStuck")
	FHazePlaySequenceData MoleStuckFinish;

	UPROPERTY(Category = "MoleStuck")
	FHazePlaySequenceData MoleStuckFinishMh;

	//In the 2D section where the mole climbs after the players
	UPROPERTY(Category = "MoleClimbing")
    FHazePlaySequenceData ClimbingStart;

	UPROPERTY(Category = "MoleClimbing")
    FHazePlaySequenceData ClimbingMove;

	UPROPERTY(Category = "MoleClimbing")
    FHazePlaySequenceData ClimbingFinish;

	UPROPERTY(Category = "CutsceneTransition")
    FHazePlaySequenceData CutsceneTransition;


};