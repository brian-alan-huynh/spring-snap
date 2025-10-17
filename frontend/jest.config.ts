import type { Config } from 'jest';

const config: Config = {
    preset: 'ts-jest',
    testEnvironment: 'jsdom',
    roots: ['<rootDir>/src'],
    moduleNameMapper: {
        '^@/(.*)$': '<rootDir>/src/$1',
    },
    transform: {
        '^.+\\.(t|j)sx?$': 'ts-jest',
    },
    setupFilesAfterEnv: ['<rootDir>/src/setupTests.ts'],
    reporters: [
        'default',
        [
            'jest-json-reporter',
            {
                outputFile: '<rootDir>/reports/codeTestsReport.json',
                suiteName: 'Frontend Code Tests',
                addFileAttribute: true,
                ancestorSeparator: ' > ',
                classNameTemplate: '{classname}',
                titleTemplate: '{classname} - {title}',
                includeConsoleOutput: true,
                usePathForSuiteName: true,
            },
        ],
    ],
};

export default config;
