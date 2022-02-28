import Vino.MinigameScore.MinigameInGameText;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

enum EMinigameState
{
	Inactive,
	PlayerInRange,
	OnePlayerInteracting,
	BothPlayersInteracting,
	Countdown,
	Playing,
	DisplayWinner
}

enum EMinigameWinner
{
	May,
	Cody,
	Draw,
}

//PURELY VISUAL
enum EScoreJuice
{
	NoChange,
	SmallChange,
	BigChange,
	NegativeChange
}

//AFFECTS SCORE BOX TYPE AT THE MOMENT
enum EScoreMode
{
	//This will be removed
	Standard,
	Laps,
	TotalScore,
	FirstTo,
	DoubleTimer
}

enum EHighScoreType
{
	RoundsWon,
	HighestScore,
	TimeElapsed
}

enum EMinigameCharacterState
{
	Waiting,
	AnnouncesPlayerArrival,
	SmallHitReaction,
	BigHitReaction,
	LoopingHitReaction,
	TopHitReaction,
	Idle,
	Exiting
}

struct FScoreHudData
{
	UPROPERTY()
	FText MinigameName;

	UPROPERTY()
	EScoreMode ScoreMode;

	UPROPERTY()
	EHighScoreType HighScoreType;

	UPROPERTY()
	bool ShowScoreBoxes = true;

	UPROPERTY()
	bool ShowHighScore = true;

	UPROPERTY()
	bool ShowTimer = false;

	UPROPERTY()
	float MayScore;

	UPROPERTY()
	float CodyScore;

	UPROPERTY()
	float CodyHighScore;

	UPROPERTY()
	float MayHighScore;

	UPROPERTY()
	float MayBestLap;
	
	UPROPERTY()
	float CodyBestLap;
	
	UPROPERTY()
	float MayLastLap;
	
	UPROPERTY()
	float CodyLastLap;

	UPROPERTY(Meta = (EditCondition = "ShowTimer"))
	float Timer;

	UPROPERTY(Meta = (EditCondition = "ShowTimer"))
	float DefaultHighscoreTimer;

	//ScoreLimit is FirstTo score to reach
	UPROPERTY()
	float ScoreLimit;
}

// struct FMinigameHighScoreAndLaps
// {
// 	UPROPERTY()
// 	float MayHighScore;

// 	UPROPERTY()
// 	float CodyHighScore; 

// 	UPROPERTY()
// 	float MayBestLap;

// 	UPROPERTY()
// 	float CodyBestLap;

// 	UPROPERTY()
// 	float MayLastLap;
	
// 	UPROPERTY()
// 	float CodyLastLap;
// }

struct FMinigameWorldWidgetSettings
{
	//Movement type - indefinite goes forever, to height reaches a set height relative from it's starting point
	UPROPERTY()
	EMinigameTextMovementType MinigameTextMovementType = EMinigameTextMovementType::AccelerateIndefinite; 
	
	UPROPERTY()
	EMinigameTextColor MinigameTextColor;
	
	//Animation juice
	UPROPERTY()
	EInGameTextJuice TextJuice = EInGameTextJuice::SmallChange;
	
	//Starting move speed
	UPROPERTY()
	float MoveSpeed = 100.f;
	
	//Time before it begins fading
	UPROPERTY()
	float TimeDuration = 3.f;
	
	//Opacity fade time once time duration is complete
	UPROPERTY()
	float FadeDuration = 2.f;
	
	//The max height it will reach
	UPROPERTY()
	float TargetHeight = 30.f; 
}

namespace MinigameCapabilityTags
{
	const FName Minigames = FName(n"Minigames");
}

enum EMinigameTag
{
	WhackACody,
	NailThrow,
	PlungerDunger,
	TugofWar,
	TankBrothers,
	LaserTennis,
	LowGravityRoom,
	Baseball,
	ThrowingHoops,
	Rodeo,
	BirdStar,
	BombRun,
	HorseDerby,
	BirdRace,
	SnowWarfare,
	ShuffleBoard,
	IcicleThrowing,
	IceRace,
	BumblebeeBasket,
	GardenSwings,
	SnailRace,
	MusicalChairs,
	TrackRunner,
	Slotcars,
	Chess,
	Volleyball
}

//*** ----------MINIGAME VO----------  ***//
namespace MinigameVOData
{
	const FName Generic_DrawCody("FoghornDBGameplayGlobalMinigameGenericDrawMay");
	const FName Generic_DrawMay("FoghornDBGameplayGlobalMinigameGenericDrawCody");
	const FName Generic_WinMay("FoghornDBGameplayGlobalMinigameGenericWinMay");
	const FName Generic_WinCody("FoghornDBGameplayGlobalMinigameGenericWinCody");
	const FName Generic_LoseMay("FoghornDBGameplayGlobalMinigameGenericLoseMay");
	const FName Generic_LoseCody("FoghornDBGameplayGlobalMinigameGenericLoseCody");
	const FName Generic_PendingStartCody("FoghornDBGameplayGlobalMinigamePendingStartCody");
	const FName Generic_PendingStartMay("FoghornDBGameplayGlobalMinigamePendingStartMay");
	const FName Generic_StartCody("FoghornDBGameplayGlobalMinigameGenericStartCody");
	const FName Generic_StartMay("FoghornDBGameplayGlobalMinigameGenericStartMay");
	const FName Generic_TauntCody("FoghornDBGameplayGlobalMinigameGenericTauntCody");
	const FName Generic_TauntMay("FoghornDBGameplayGlobalMinigameGenericTauntMay");
	const FName Generic_FailCody("FoghornDBGameplayGlobalMinigameGenericFailCody");
	const FName Generic_FailMay("FoghornDBGameplayGlobalMinigameGenericFailMay");


	const FName WhackACody_Start("FoghornDBShedMainWhackACodyStart");
	const FName WhackACody_MayWin("FoghornDBShedMainWhackACodyMayWins");
	const FName WhackACody_CodyWin("FoghornDBShedMainWhackACodyCodyWins");
	const FName WhackACody_TauntCody("FoghornDBShedMainWhackACodyTauntCody");
	const FName WhackACody_TauntMay("FoghornDBShedMainWhackACodyTauntMay");


	const FName NailWheel_ApproachCody("FoghornDBShedMainNailWheelApproachCody");
	const FName NailWheel_ApproachMay("FoghornDBShedMainNailWheelApproachMay");
	const FName NailWheel_Start("FoghornDBShedMainNailWheelStart");
	const FName NailWheel_CodyWin("FoghornDBShedMainNailWheelCodyWins");
	const FName NailWheel_MayWin("FoghornDBShedMainNailWheelMayWins");
	const FName NailWheel_TauntCody("FoghornDBShedMainNailWheelTauntCody");
	const FName NailWheel_TauntMay("FoghornDBShedMainNailWheelTauntMay");
	

	const FName TugofWar_ApproachCody("FoghornDBTreeSquirrelHomeTugOfWarApproachCody");
	const FName TugofWar_ApproachMay("FoghornDBTreeSquirrelHomeTugOfWarApproachMay");
	const FName TugofWar_Start("FoghornDBTreeSquirrelHomeTugOfWarStart");
	const FName TugofWar_CodyWin("FoghornDBTreeSquirrelHomeTugOfWarCodyWins");	
	const FName TugofWar_MayWin("FoghornDBTreeSquirrelHomeTugOfWarMayWins");
	const FName TugofWar_TauntCody("FoghornDBTreeSquirrelHomeTugOfWarTauntCody");
	const FName TugofWar_TauntMay("FoghornDBTreeSquirrelHomeTugOfWarTauntMay");


	const FName PlungerDunger_ApproachCody("FoghornDBTreeWaspsnestPlungerApproachCody");
	const FName PlungerDunger_ApproachMay("FoghornDBTreeWaspsnestPlungerApproachMay");
	const FName PlungerDunger_Start("FoghornDBTreeWaspsnestPlungerStart");
	const FName PlungerDunger_CodyWin("FoghornDBTreeWaspsnestPlungerCodyWins");	
	const FName PlungerDunger_MayWin("FoghornDBTreeWaspsnestPlungerMayWins");
	const FName PlungerDunger_TauntCody("FoghornDBTreeWaspsnestPlungerTauntCody");
	const FName PlungerDunger_TauntMay("FoghornDBTreeWaspsnestPlungerTauntMay");


	const FName TankBrothers_ApproachCody("FoghornDBPlayroomPillowfortTankBrothersApproachCody");
	const FName TankBrothers_ApproachMay("FoghornDBPlayroomPillowfortTankBrothersApproachMay");
	const FName TankBrothers_Start("FoghornDBPlayroomPillowfortHazeBoyTankBrothersStart");
	const FName TankBrothers_CodyWin("FoghornDBPlayroomPillowfortHazeBoyTankBrothersCodyWins");	
	const FName TankBrothers_MayWin("FoghornDBPlayroomPillowfortHazeBoyTankBrothersMayWins");
	const FName TankBrothers_TauntCody("FoghornDBPlayroomPillowfortHazeBoyTankBrothersTauntCody");
	const FName TankBrothers_TauntMay("FoghornDBPlayroomPillowfortHazeBoyTankBrothersTauntMay");


	const FName LaserTennis_ApproachCody("FoghornDBPlayroomSpacestationLaserTennisApproachCody");
	const FName LaserTennis_ApproachMay("FoghornDBPlayroomSpacestationLaserTennisApproachMay");
	const FName LaserTennis_Start("FoghornDBPlayroomSpacestationLaserTennisStart");
	const FName LaserTennis_CodyWin("FoghornDBPlayroomSpacestationLaserTennisCodyWins");	
	const FName LaserTennis_MayWin("FoghornDBPlayroomSpacestationLaserTennisMayWins");
	const FName LaserTennis_TauntCody("FoghornDBPlayroomSpacestationLaserTennisTauntCody");
	const FName LaserTennis_TauntMay("FoghornDBPlayroomSpacestationLaserTennisTauntMay");


	const FName LowGravityRoom_ApproachCody("FoghornDBPlayroomSpacestationLowGravityRoomApproachCody");
	const FName LowGravityRoom_ApproachMay("FoghornDBPlayroomSpacestationLowGravityRoomApproachMay");
	const FName LowGravityRoom_Start("FoghornDBPlayroomSpacestationLowGravityRoomStart");
	const FName LowGravityRoom_CodyWin("FoghornDBPlayroomSpacestationLowGravityRoomCodyWins");
	const FName LowGravityRoom_MayWin("FoghornDBPlayroomSpacestationLowGravityRoomMayWins");
	const FName LowGravityRoom_TauntCody("FoghornDBPlayroomSpacestationLowGravityRoomTauntCody");
	const FName LowGravityRoom_TauntMay("FoghornDBPlayroomSpacestationLowGravityRoomTauntMay");


	const FName Baseball_ApproachCody("FoghornDBPlayroomHopscotchBaseballApproachCody");
	const FName Baseball_ApproachMay("FoghornDBPlayroomHopscotchBaseballApproachMay");
	const FName Baseball_Start("FoghornDBPlayroomHopscotchBaseballStart");
	const FName Baseball_CodyWin("FoghornDBPlayroomHopscotchBaseballCodyWins");	
	const FName Baseball_MayWin("FoghornDBPlayroomHopscotchBaseballMayWins");
	const FName Baseball_TauntCody("FoghornDBPlayroomHopscotchBaseballTauntCody");
	const FName Baseball_TauntMay("FoghornDBPlayroomHopscotchBaseballTauntMay");


	const FName ThrowingHoops_ApproachCody("FoghornDBPlayroomHopscotchThrowingHoopsApproachCody");
	const FName ThrowingHoops_ApproachMay("FoghornDBPlayroomHopscotchThrowingHoopsApproachMay");
	const FName ThrowingHoops_Start("FoghornDBPlayroomHopscotchThrowingHoopsStart");
	const FName ThrowingHoops_CodyWin("FoghornDBPlayroomHopscotchThrowingHoopsCodyWins");
	const FName ThrowingHoops_MayWin("FoghornDBPlayroomHopscotchThrowingHoopsMayWins");		
	const FName ThrowingHoops_TauntCody("FoghornDBPlayroomHopscotchThrowingHoopsTauntCody");
	const FName ThrowingHoops_TauntMay("FoghornDBPlayroomHopscotchThrowingHoopsTauntMay");


	const FName Rodeo_ApproachCody("FoghornDBPlayroomHopscotchRodeoApproachCody");
	const FName Rodeo_ApproachMay("FoghornDBPlayroomHopscotchRodeoApproachMay");
	const FName Rodeo_Start("FoghornDBPlayroomHopscotchRodeoStart");
	const FName Rodeo_CodyWin("FoghornDBPlayroomHopscotchRodeoCodyWins");
	const FName Rodeo_MayWin("FoghornDBPlayroomHopscotchRodeoMayWins");
	const FName Rodeo_TauntCody("FoghornDBPlayroomHopscotchRodeoTauntCody");
	const FName Rodeo_TauntMay("FoghornDBPlayroomHopscotchRodeoTauntMay");


	const FName Birdstar_ApproachCody("FoghornDBPlayroomCourtyardBirdStarApproachCody");
	const FName Birdstar_ApproachMay("FoghornDBPlayroomCourtyardBirdStarApproachMay");
	const FName Birdstar_Start("FoghornDBPlayroomCourtyardBirdStarStart");
	const FName Birdstar_CodyWin("FoghornDBPlayroomCourtyardBirdStarCodyWins");	
	const FName Birdstar_MayWin("FoghornDBPlayroomCourtyardBirdStarMayWins");
	const FName Birdstar_TauntCody("FoghornDBPlayroomCourtyardBirdStarTauntCody");
	const FName Birdstar_TauntMay("FoghornDBPlayroomCourtyardBirdStarTauntMay");


	const FName BombRun_ApproachCody("FoghornDBClockworkOutsideBombRunApproachCody");
	const FName BombRun_ApproachMay("FoghornDBClockworkOutsideBombRunApproachMay");
	const FName BombRun_Start("FoghornDBClockworkOutsideBombRunStart");
	const FName BombRun_CodyWin("FoghornDBClockworkOutsideBombRunCodyWins");	
	const FName BombRun_MayWin("FoghornDBClockworkOutsideBombRunMayWins");
	const FName BombRun_TauntCody("FoghornDBClockworkOutsideBombRunTauntCody");
	const FName BombRun_TauntMay("FoghornDBClockworkOutsideBombRunTauntMay");


	const FName HorseDerby_ApproachCody("FoghornDBClockworkOutsideHorseDerbyApproachCody");
	const FName HorseDerby_ApproachMay("FoghornDBClockworkOutsideHorseDerbyApproachMay");
	const FName HorseDerby_Start("FoghornDBClockworkOutsideHorseDerbyStart");
	const FName HorseDerby_CodyWin("FoghornDBClockworkOutsideHorseDerbyCodyWins");
	const FName HorseDerby_MayWin("FoghornDBClockworkOutsideHorseDerbyMayWins");
	const FName HorseDerby_TauntCody("FoghornDBClockworkOutsideHorseDerbyTauntCody");
	const FName HorseDerby_TauntMay("FoghornDBClockworkOutsideHorseDerbyTauntMay");


	const FName SnowWarfare_ApproachCody("FoghornDBSnowGlobeTownSnowWarfareApproachCody");
	const FName SnowWarfare_ApproachMay("FoghornDBSnowGlobeTownSnowWarfareApproachMay");
	const FName SnowWarfare_Start("FoghornDBSnowGlobeTownSnowWarfareStart");
	const FName SnowWarfare_CodyWin("FoghornDBSnowGlobeTownSnowWarfareCodyWins");
	const FName SnowWarfare_MayWin("FoghornDBSnowGlobeTownSnowWarfareMayWins");
	const FName SnowWarfare_TauntCody("FoghornDBSnowGlobeTownSnowWarfareTauntCody");
	const FName SnowWarfare_TauntMay("FoghornDBSnowGlobeTownSnowWarfareTauntMay");


	const FName ShuffleBoard_ApproachCody("FoghornDBSnowGlobeTownShuffleBoardApproachCody");
	const FName ShuffleBoard_ApproachMay("FoghornDBSnowGlobeTownShuffleBoardApproachMay");
	const FName ShuffleBoard_Start("FoghornDBSnowGlobeTownShuffleBoardStart");
	const FName ShuffleBoard_CodyWin("FoghornDBSnowGlobeTownShuffleBoardCodyWins");
	const FName ShuffleBoard_MayWin("FoghornDBSnowGlobeTownShuffleBoardMayWins");
	const FName ShuffleBoard_TauntCody("FoghornDBSnowGlobeTownShuffleBoardTauntCody");
	const FName ShuffleBoard_TauntMay("FoghornDBSnowGlobeTownShuffleBoardTauntMay");


	const FName IcicleThrowing_ApproachCody("FoghornDBSnowGlobeTownIcicleThrowingApproachCody");
	const FName IcicleThrowing_ApproachMay("FoghornDBSnowGlobeTownIcicleThrowingApproachMay");
	const FName IcicleThrowing_Start("FoghornDBSnowGlobeTownIcicleThrowingStart");
	const FName IcicleThrowing_CodyWin("FoghornDBSnowGlobeTownIcicleThrowingCodyWins");
	const FName IcicleThrowing_MayWin("FoghornDBSnowGlobeTownIcicleThrowingMayWins");
	const FName IcicleThrowing_TauntCody("FoghornDBSnowGlobeTownIcicleThrowingTauntCody");
	const FName IcicleThrowing_TauntMay("FoghornDBSnowGlobeTownIcicleThrowingTauntMay");


	const FName IceRace_ApproachCody("FoghornDBSnowGlobeLakeIceRaceApproachCody");
	const FName IceRace_ApproachMay("FoghornDBSnowGlobeLakeIceRaceApproachMay");
	const FName IceRace_Start("FoghornDBSnowGlobeLakeIceRaceStart");
	const FName IceRace_CodyWin("FoghornDBSnowGlobeLakeIceRaceCodyWins");
	const FName IceRace_MayWin("FoghornDBSnowGlobeLakeIceRaceMayWins");
	const FName IceRace_TauntCody("FoghornDBSnowGlobeLakeIceRaceTauntCody");
	const FName IceRace_TauntMay("FoghornDBSnowGlobeLakeIceRaceTauntMay");


	const FName BumblebeeBasket_ApproachCody("FoghornDBGardenShrubberyBumbleBeeBasketApproachCody");
	const FName BumblebeeBasket_ApproachMay("FoghornDBGardenShrubberyBumbleBeeBasketApproachMay");
	const FName BumblebeeBasket_Start("FoghornDBGardenShrubberyBumbleBeeBasketStart");
	const FName BumblebeeBasket_CodyWin("FoghornDBGardenShrubberyBumbleBeeBasketCodyWins");
	const FName BumblebeeBasket_MayWin("FoghornDBGardenShrubberyBumbleBeeBasketMayWins");
	const FName BumblebeeBasket_TauntCody("FoghornDBGardenShrubberyBumbleBeeBasketTauntCody");
	const FName BumblebeeBasket_TauntMay("FoghornDBGardenShrubberyBumbleBeeBasketTauntMay");


	const FName GardenSwings_ApproachCody("FoghornDBGardenShrubberyGardenSwingsApproachCody");
	const FName GardenSwings_ApproachMay("FoghornDBGardenShrubberyGardenSwingsApproachMay");
	const FName GardenSwings_Start("FoghornDBGardenShrubberyGardenSwingsStart");
	const FName GardenSwings_CodyWin("FoghornDBGardenShrubberyGardenSwingsCodyWins");
	const FName GardenSwings_MayWin("FoghornDBGardenShrubberyGardenSwingsMayWins");
	const FName GardenSwings_TauntCody("FoghornDBGardenShrubberyGardenSwingsTauntCody");
	const FName GardenSwings_TauntMay("FoghornDBGardenShrubberyGardenSwingsTauntMay");


	const FName SnailRace_ApproachCody("FoghornDBGardenFrogpondSnailRaceApproachCody");
	const FName SnailRace_ApproachMay("FoghornDBGardenFrogpondSnailRaceApproachMay");
	const FName SnailRace_Start("FoghornDBGardenFrogpondSnailRaceStart");
	const FName SnailRace_CodyWin("FoghornDBGardenFrogpondSnailRaceCodyWins");
	const FName SnailRace_MayWin("FoghornDBGardenFrogpondSnailRaceMayWins");
	const FName SnailRace_TauntCody("FoghornDBGardenFrogpondSnailRaceTauntCody");
	const FName SnailRace_TauntMay("FoghornDBGardenFrogpondSnailRaceTauntMay");
	

	const FName MusicalChairs_ApproachCody("FoghornDBMusicConcerthallMusicalChairsApproachCody");
	const FName MusicalChairs_ApproachMay("FoghornDBMusicConcerthallMusicalChairsApproachMay");
	const FName MusicalChairs_Start("FoghornDBMusicConcerthallMusicalChairsStart");
	const FName MusicalChairs_CodyWin("FoghornDBMusicConcerthallMusicalChairsCodyWins");
	const FName MusicalChairs_MayWin("FoghornDBMusicConcerthallMusicalChairsMayWins");
	const FName MusicalChairs_TauntCody("FoghornDBMusicConcerthallMusicalChairsTauntCody");
	const FName MusicalChairs_TauntMay("FoghornDBMusicConcerthallMusicalChairsTauntMay");
	

	const FName TrackRunner_ApproachCody("FoghornDBMusicConcerthallTrackRunnerApproachCody");
	const FName TrackRunner_ApproachMay("FoghornDBMusicConcerthallTrackRunnerApproachMay");
	const FName TrackRunner_Start("FoghornDBMusicConcerthallTrackRunnerStart");
	const FName TrackRunner_CodyWin("FoghornDBMusicConcerthallTrackRunnerCodyWins");
	const FName TrackRunner_MayWin("FoghornDBMusicConcerthallTrackRunnerMayWins");
	const FName TrackRunner_TauntCody("FoghornDBMusicConcerthallTrackRunnerTauntCody");
	const FName TrackRunner_TauntMay("FoghornDBMusicConcerthallTrackRunnerTauntMay");


	const FName Slotcars_ApproachCody("FoghornDBMusicConcerthallSlotcarsApproachCody");
	const FName Slotcars_ApproachMay("FoghornDBMusicConcerthallSlotcarsApproachMay");
	const FName Slotcars_Start("FoghornDBMusicConcerthallSlotcarsStart");
	const FName Slotcars_CodyWin("FoghornDBMusicConcerthallSlotcarsCodyWins");
	const FName Slotcars_MayWin("FoghornDBMusicConcerthallSlotcarsMayWins");
	const FName Slotcars_TauntCody("FoghornDBMusicConcerthallSlotcarsTauntCody");
	const FName Slotcars_TauntMay("FoghornDBMusicConcerthallSlotcarsTauntMay");


	const FName Chess_ApproachCody("FoghornDBMusicConcertHallChessApproachCody");
	const FName Chess_ApproachMay("FoghornDBMusicConcertHallChessApproachMay");
	const FName Chess_Start("FoghornDBMusicConcerthallChessStart");
	const FName Chess_CodyWin("FoghornDBMusicConcerthallChessCodyWins");
	const FName Chess_MayWin("FoghornDBMusicConcerthallChessMayWins");
	const FName Chess_TauntCody("FoghornDBMusicConcerthallChessTauntCody");
	const FName Chess_TauntMay("FoghornDBMusicConcerthallChessTauntMay");


	const FName Volleyball_ApproachCody("FoghornDBMusicClassicVolleyballApproachCody");
	const FName Volleyball_ApproachMay("FoghornDBMusicClassicVolleyballApproachMay");
	const FName Volleyball_Start("FoghornDBMusicClassicVolleyballStart");
	const FName Volleyball_CodyWin("FoghornDBMusicClassicVolleyballCodyWins");
	const FName Volleyball_MayWin("FoghornDBMusicClassicVolleyballMayWins");
	const FName Volleyball_TauntCody("FoghornDBMusicClassicVolleyballTauntCody");
	const FName Volleyball_TauntMay("FoghornDBMusicClassicVolleyballTauntMay");
}

void MinigameVOPlayApproach(AHazePlayerCharacter Player, EMinigameTag Tag, UFoghornVOBankDataAssetBase VOBank)
{
	switch(Tag)
	{
		case EMinigameTag::NailThrow:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::NailWheel_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::NailWheel_ApproachMay);

		break;

		case EMinigameTag::PlungerDunger:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::PlungerDunger_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::PlungerDunger_ApproachMay);
				
		break;

		case EMinigameTag::TugofWar:
		
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TugofWar_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TugofWar_ApproachMay);

		break;

		case EMinigameTag::TankBrothers:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TankBrothers_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TankBrothers_ApproachMay);

		break;

		case EMinigameTag::LaserTennis:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::LaserTennis_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::LaserTennis_ApproachMay);

		break;
		
		case EMinigameTag::LowGravityRoom:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::LowGravityRoom_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::LowGravityRoom_ApproachMay);

		break;

		case EMinigameTag::Baseball:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Baseball_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Baseball_ApproachMay);

		break;

		case EMinigameTag::ThrowingHoops:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::ThrowingHoops_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::ThrowingHoops_ApproachMay);

		break;

		case EMinigameTag::Rodeo:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Rodeo_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Rodeo_ApproachMay);

		break;

		case EMinigameTag::BirdStar:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Birdstar_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Birdstar_ApproachMay);

		break;

		case EMinigameTag::BombRun:
					
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::BombRun_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::BombRun_ApproachMay);

		break;

		case EMinigameTag::HorseDerby:
					
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::HorseDerby_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::HorseDerby_ApproachMay);

		break;

		// case EMinigameTag::BirdRace:
		// break;

		case EMinigameTag::SnowWarfare:
							
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnowWarfare_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnowWarfare_ApproachMay);

		break;

		case EMinigameTag::ShuffleBoard:
									
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::ShuffleBoard_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::ShuffleBoard_ApproachMay);

		break;

		case EMinigameTag::IcicleThrowing:
											
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::IcicleThrowing_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::IcicleThrowing_ApproachMay);

		break;

		case EMinigameTag::IceRace:
											
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::IceRace_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::IceRace_ApproachMay);

		break;

		case EMinigameTag::BumblebeeBasket:
													
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::BumblebeeBasket_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::BumblebeeBasket_ApproachMay);

		break;

		case EMinigameTag::GardenSwings:
															
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::GardenSwings_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::GardenSwings_ApproachMay);

		break;

		case EMinigameTag::SnailRace:
																	
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnailRace_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnailRace_ApproachMay);

		break;

		case EMinigameTag::MusicalChairs:
																			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::MusicalChairs_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::MusicalChairs_ApproachMay);

		break;

		case EMinigameTag::TrackRunner:
																					
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TrackRunner_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TrackRunner_ApproachMay);

		break;

		case EMinigameTag::Slotcars:
																							
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Slotcars_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Slotcars_ApproachMay);

		break;

		case EMinigameTag::Chess:
																									
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Chess_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Chess_ApproachMay);

		break;

		case EMinigameTag::Volleyball:
																											
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Volleyball_ApproachCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Volleyball_ApproachMay);

		break;
	}
}

void MinigameVOPlayGenericPendingState(AHazePlayerCharacter Player, UFoghornVOBankDataAssetBase VOBank)
{
	if (Player.IsCody())
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_PendingStartCody);
	else
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_PendingStartMay);
}

void MinigameVOPlayStart(UFoghornVOBankDataAssetBase VOBank, EMinigameTag Tag)
{
	switch(Tag)
	{
		case EMinigameTag::WhackACody:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::WhackACody_Start);
		break;

		case EMinigameTag::NailThrow:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::NailWheel_Start);
		break;

		case EMinigameTag::PlungerDunger:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::PlungerDunger_Start);
		break;

		case EMinigameTag::TugofWar:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::TugofWar_Start);
		break;

		case EMinigameTag::TankBrothers:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::TankBrothers_Start);
		break;

		case EMinigameTag::LaserTennis:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::LaserTennis_Start);
		break;
		
		case EMinigameTag::LowGravityRoom:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::LowGravityRoom_Start);
		break;

		case EMinigameTag::Baseball:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::Baseball_Start);
		break;

		case EMinigameTag::ThrowingHoops:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::ThrowingHoops_Start);
		break;

		case EMinigameTag::Rodeo:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::Rodeo_Start);
		break;

		case EMinigameTag::BirdStar:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::Birdstar_Start);
		break;

		case EMinigameTag::BombRun:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::BombRun_Start);
		break;

		case EMinigameTag::HorseDerby:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::HorseDerby_Start);
		break;

		// case EMinigameTag::BirdRace:
		// break;

		case EMinigameTag::SnowWarfare:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnowWarfare_Start);
		break;

		case EMinigameTag::ShuffleBoard:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::ShuffleBoard_Start);
		break;

		case EMinigameTag::IcicleThrowing:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::IcicleThrowing_Start);
		break;

		case EMinigameTag::IceRace:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::IceRace_Start);
		break;

		case EMinigameTag::BumblebeeBasket:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::BumblebeeBasket_Start);
		break;

		case EMinigameTag::GardenSwings:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::GardenSwings_Start);
		break;

		case EMinigameTag::SnailRace:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnailRace_Start);
		break;

		case EMinigameTag::MusicalChairs:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::MusicalChairs_Start);
		break;

		case EMinigameTag::TrackRunner:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::TrackRunner_Start);
		break;

		case EMinigameTag::Slotcars:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::Slotcars_Start);
		break;

		case EMinigameTag::Chess:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::Chess_Start);
		break;

		case EMinigameTag::Volleyball:
			PlayFoghornVOBankEvent(VOBank, MinigameVOData::Volleyball_Start);
		break;
	}
}

void MinigameVOPlayGenericStart(UFoghornVOBankDataAssetBase VOBank, AHazePlayerCharacter Player)
{
	if (Player.IsMay())
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_StartCody);
	else
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_StartMay);
}

void MinigameVOPlayGenericDraw(UFoghornVOBankDataAssetBase VOBank, bool bPlayMay)
{
	if (bPlayMay)
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_DrawMay);
	else
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_DrawCody);
}

void MinigameVOPlayLose(AHazePlayerCharacter Player, EMinigameTag Tag, UFoghornVOBankDataAssetBase VOGenericBank)
{
	if (Player.IsCody())
		PlayFoghornVOBankEvent(VOGenericBank, MinigameVOData::Generic_LoseCody);
	else
		PlayFoghornVOBankEvent(VOGenericBank, MinigameVOData::Generic_LoseMay);
}

void MinigameVOPlayWin(AHazePlayerCharacter Player, EMinigameTag Tag, UFoghornVOBankDataAssetBase VOLevelBank, UFoghornVOBankDataAssetBase VOGenericBank)
{
	int ChosenIndex = FMath::RandRange(0, 1);

	if (Player.IsCody())
	{
		if (ChosenIndex == 0)
			PlayFoghornVOBankEvent(VOGenericBank, MinigameVOData::Generic_WinCody);
		else
			PlayFoghornVOBankEvent(VOGenericBank, MinigameVOData::Generic_LoseMay);
	}
	else
	{
		if (ChosenIndex == 0)
			PlayFoghornVOBankEvent(VOGenericBank, MinigameVOData::Generic_WinMay);
		else
			PlayFoghornVOBankEvent(VOGenericBank, MinigameVOData::Generic_LoseCody);
	}

	switch(Tag)
	{
		case EMinigameTag::WhackACody:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::WhackACody_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::WhackACody_MayWin);

		break;

		case EMinigameTag::NailThrow:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::NailWheel_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::NailWheel_MayWin);

		break;

		case EMinigameTag::PlungerDunger:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::PlungerDunger_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::PlungerDunger_MayWin);
				
		break;

		case EMinigameTag::TugofWar:
		
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::TugofWar_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::TugofWar_MayWin);

		break;

		case EMinigameTag::TankBrothers:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::TankBrothers_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::TankBrothers_MayWin);

		break;

		case EMinigameTag::LaserTennis:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::LaserTennis_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::LaserTennis_MayWin);

		break;
		
		case EMinigameTag::LowGravityRoom:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::LowGravityRoom_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::LowGravityRoom_MayWin);

		break;

		case EMinigameTag::Baseball:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Baseball_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Baseball_MayWin);

		break;

		case EMinigameTag::ThrowingHoops:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::ThrowingHoops_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::ThrowingHoops_MayWin);

		break;

		case EMinigameTag::Rodeo:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Rodeo_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Rodeo_MayWin);

		break;

		case EMinigameTag::BirdStar:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Birdstar_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Birdstar_MayWin);

		break;

		case EMinigameTag::BombRun:
					
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::BombRun_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::BombRun_MayWin);

		break;

		case EMinigameTag::HorseDerby:
					
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::HorseDerby_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::HorseDerby_MayWin);

		break;

		case EMinigameTag::SnowWarfare:
							
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::SnowWarfare_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::SnowWarfare_MayWin);

		break;

		case EMinigameTag::ShuffleBoard:
									
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::ShuffleBoard_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::ShuffleBoard_MayWin);

		break;

		case EMinigameTag::IcicleThrowing:
											
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::IcicleThrowing_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::IcicleThrowing_MayWin);

		break;

		case EMinigameTag::IceRace:
											
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::IceRace_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::IceRace_MayWin);

		break;

		case EMinigameTag::BumblebeeBasket:
													
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::BumblebeeBasket_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::BumblebeeBasket_MayWin);

		break;

		case EMinigameTag::GardenSwings:
															
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::GardenSwings_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::GardenSwings_MayWin);

		break;

		case EMinigameTag::SnailRace:
																	
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::SnailRace_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::SnailRace_MayWin);

		break;

		case EMinigameTag::MusicalChairs:
																			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::MusicalChairs_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::MusicalChairs_MayWin);

		break;

		case EMinigameTag::TrackRunner:
																					
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::TrackRunner_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::TrackRunner_MayWin);

		break;

		case EMinigameTag::Slotcars:
																							
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Slotcars_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Slotcars_MayWin);

		break;

		case EMinigameTag::Chess:
																									
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Chess_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Chess_MayWin);

		break;

		case EMinigameTag::Volleyball:
																											
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Volleyball_CodyWin);
			else
				PlayFoghornVOBankEvent(VOLevelBank, MinigameVOData::Volleyball_MayWin);

		break;
	}
}

void MinigameVOPlayGenericTaunt(AHazePlayerCharacter Player, UFoghornVOBankDataAssetBase VOBank)
{
	if (Player.IsCody())
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_TauntCody);
	else
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_TauntMay);
}

void MinigameVOPlayUniqueTaunt(AHazePlayerCharacter Player, EMinigameTag Tag, UFoghornVOBankDataAssetBase VOBank)
{
	switch(Tag)
	{
		case EMinigameTag::WhackACody:
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::WhackACody_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::WhackACody_TauntMay);
				
		break;

		case EMinigameTag::NailThrow:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::NailWheel_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::NailWheel_TauntMay);

		break;

		case EMinigameTag::PlungerDunger:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::PlungerDunger_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::PlungerDunger_TauntMay);
				
		break;

		case EMinigameTag::TugofWar:
		
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TugofWar_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TugofWar_TauntMay);

		break;

		case EMinigameTag::TankBrothers:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TankBrothers_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TankBrothers_TauntMay);

		break;

		case EMinigameTag::LaserTennis:

			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::LaserTennis_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::LaserTennis_TauntMay);

		break;
		
		case EMinigameTag::LowGravityRoom:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::LowGravityRoom_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::LowGravityRoom_TauntMay);

		break;

		case EMinigameTag::Baseball:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Baseball_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Baseball_TauntMay);

		break;

		case EMinigameTag::ThrowingHoops:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::ThrowingHoops_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::ThrowingHoops_TauntMay);

		break;

		case EMinigameTag::Rodeo:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Rodeo_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Rodeo_TauntMay);

		break;

		case EMinigameTag::BirdStar:
			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Birdstar_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Birdstar_TauntMay);

		break;

		case EMinigameTag::BombRun:
					
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::BombRun_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::BombRun_TauntMay);

		break;

		case EMinigameTag::HorseDerby:
					
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::HorseDerby_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::HorseDerby_TauntMay);

		break;

		// case EMinigameTag::BirdRace:
		// break;

		case EMinigameTag::SnowWarfare:
							
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnowWarfare_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnowWarfare_TauntMay);

		break;

		case EMinigameTag::ShuffleBoard:
									
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::ShuffleBoard_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::ShuffleBoard_TauntMay);

		break;

		case EMinigameTag::IcicleThrowing:
											
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::IcicleThrowing_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::IcicleThrowing_TauntMay);

		break;

		case EMinigameTag::IceRace:
											
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::IceRace_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::IceRace_TauntMay);

		break;

		case EMinigameTag::BumblebeeBasket:
													
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::BumblebeeBasket_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::BumblebeeBasket_TauntMay);

		break;

		case EMinigameTag::GardenSwings:
															
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::GardenSwings_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::GardenSwings_TauntMay);

		break;

		case EMinigameTag::SnailRace:
																	
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnailRace_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::SnailRace_TauntMay);

		break;

		case EMinigameTag::MusicalChairs:
																			
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::MusicalChairs_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::MusicalChairs_TauntMay);

		break;

		case EMinigameTag::TrackRunner:
																					
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TrackRunner_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::TrackRunner_TauntMay);

		break;

		case EMinigameTag::Slotcars:
																							
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Slotcars_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Slotcars_TauntMay);

		break;

		case EMinigameTag::Chess:
																									
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Chess_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Chess_TauntMay);

		break;

		case EMinigameTag::Volleyball:
																											
			if (Player.IsCody())
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Volleyball_TauntCody);
			else
				PlayFoghornVOBankEvent(VOBank, MinigameVOData::Volleyball_TauntMay);

		break;
	}
}

void MinigameVOPlayGenericFail(AHazePlayerCharacter Player, UFoghornVOBankDataAssetBase VOBank)
{
	if (Player.IsCody())
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_FailCody);
	else
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_FailMay);
}

void MinigameVOPlayPendingStart(AHazePlayerCharacter Player, UFoghornVOBankDataAssetBase VOBank)
{
	if (Player.IsCody())
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_PendingStartCody);
	else
		PlayFoghornVOBankEvent(VOBank, MinigameVOData::Generic_PendingStartMay);
}