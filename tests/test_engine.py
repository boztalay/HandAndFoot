import json
import os
import subprocess
import sys

"""
Sample test case

{
    "description": "Test Case Description",
    "players": [
        "player_1",
        "player_2",
        "player_3",
        "player_4"
    ],
    "initial_deck": [
        {
            "suit": "hearts",
            "rank": "two"
        }
        ...
    ],
    "actions": [
        {
            "type": "action_type",
            ...
        }
        ...
    ],
    "final_state": {
        "discard_pile": [
            {
                "suit": "hearts",
                "rank": "two"
            }
            ...
        ],
        "players": [
            {
                "name": "player_1",
                "points": {
                    "ninety": {
                        "in_hand": 50,
                        "in_foot": 0,
                        "books": 500,
                        "laid_down": 300
                    }
                },
                "hand": [
                    {
                        "suit": "hearts",
                        "rank": "two"
                    }
                    ...
                ],
                "foot": [ ],
                "books": [
                    {
                        "rank": "five",
                        "cards": [
                            {
                                "suit": "diamonds",
                                "rank": "five"
                            }
                            ...
                        ]
                    },
                    ...
                ]
            }
            ...
        ]
    }
    "
}
"""

def main(enginePath, testCasePaths):
    results = []

    for testCasePath in testCasePaths:
        if os.path.isdir(testCasePath):
            results.extend(runTestCasesInDir(enginePath, testCasePath))
        else:
            results.append(runTestCase(enginePath, testCasePath))

    failedTests = [result for result in results if (result[1] == False)]

    plural = "s" if len(results) == 1 else ""
    print("Failed %d of %d test%s" % (len(failedTests), len(results), plural))

    if len(failedTests) > 0:
        print("Failing tests:")
        for failedTest in failedTests:
            print(failedTest[0])

def runTestCasesInDir(enginePath, testCaseDir):
    results = []

    testCasesInDir = [item for item in os.listdir(testCaseDir) if os.path.isfile(item)]
    for testCaseFileName in testCasesInDir:
        testCasePath = os.path.join(testCaseDir, testCaseFileName)
        results.append(runTestCase(enginePath, testCasePath))

    return results

def runTestCase(enginePath, testCasePath):
    actualFinalStateString = subprocess.check_output("%s %s" % (enginePath, testCasePath), shell=True)
    actualFinalState = json.loads(actualFinalStateString)

    testCase = json.load(testCasePath)
    expectedFinalState = testCase["final_state"]

    passed = (actualFinalState == expectedFinalState)

    return (testCasePath, passed)

def printUsageAndExit():
    fileName = os.path.split(__file__)[1]

    print("Usage:")
    print("    python %s <ENGINE PATH> [<TEST_CASE_PATH | TEST_CASE_DIR> ...]" % fileName)

    sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        printUsageAndExit()

    enginePath = sys.argv[1]
    testCasePaths = sys.argv[2:]

    main(enginePath, testCasePaths)
